require 'active_record/associations'
require 'active_record/validations'
require 'active_support/concern'

module Caprese
  module Persistence
    extend ActiveSupport::Concern

    included do
      # Rescue from instances where required parameters are missing
      #
      # @note The only instance this may be called, at least in JSON API settings, is a
      #   missing params['data'] param
      rescue_from ActionController::ParameterMissing do |e|
        rescue_with_handler RequestDocumentInvalidError.new(field: :base)
      end

      rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved do |e|
        if e.record
          rescue_with_handler RecordInvalidError.new(e.record, engaged_field_aliases)
        else
          rescue_with_handler ActionForbiddenError.new
        end
      end

      rescue_from ActiveRecord::RecordNotDestroyed do |e|
        rescue_with_handler ActionForbiddenError.new
      end

      rescue_from ActiveRecord::DeleteRestrictionError do |e|
        rescue_with_handler DeleteRestrictedError.new(e.message)
      end
    end

    # Creates a new record of whatever type a given controller manages
    #
    # @note For this action to succeed, the given controller must define `create_params`
    #   @see #create_params
    def create
      fail_on_type_mismatch(data_params[:type])

      @queried_record = queried_record_scope.build

      execute_after_initialize_callbacks(queried_record)

      assign_changes_from_document(queried_record, data_params.to_unsafe_h, permitted_params_for(:create))

      execute_before_create_callbacks(queried_record)
      execute_before_save_callbacks(queried_record)

      fail RecordInvalidError.new(queried_record, engaged_field_aliases) if queried_record.errors.any?

      queried_record.save!

      persist_collection_relationships(queried_record)

      execute_after_create_callbacks(queried_record)
      execute_after_save_callbacks(queried_record)

      render(
        json: queried_record,
        status: :created,
        fields: query_params[:fields].try(:to_unsafe_hash),
        include: query_params[:include]
      )
    end

    # Updates a record of whatever type a given controller manages
    #
    # @note For this action to succeed, the given controller must define `update_params`
    #   @see #update_params
    def update
      fail_on_type_mismatch(data_params[:type])

      execute_before_update_assign_callbacks(queried_record)

      assign_changes_from_document(queried_record, data_params.to_unsafe_h, permitted_params_for(:update))

      execute_before_update_callbacks(queried_record)
      execute_before_save_callbacks(queried_record)

      fail RecordInvalidError.new(queried_record, engaged_field_aliases) if queried_record.errors.any?

      queried_record.save!

      execute_after_update_callbacks(queried_record)
      execute_after_save_callbacks(queried_record)

      render(
        json: queried_record,
        fields: query_params[:fields].try(:to_unsafe_hash),
        include: query_params[:include]
      )
    end

    # Destroys a record of whatever type a given controller manages
    #
    # 1. Execute any before_destroy callbacks, with the record to be destroyed passed in
    # 2. Destroy the record, ensuring that it checks the model for dependencies before doing so
    # 3. Execute any after_destroy callbacks, with the destroyed resource passed in
    # 4. Return 204 No Content if the record was successfully deleted
    def destroy
      execute_before_destroy_callbacks(queried_record)
      queried_record.destroy!
      execute_after_destroy_callbacks(queried_record)

      head :no_content
    end

    private

    # Requires the data param standard to JSON API
    # @note If data is an array, RequestDocumentInvalidError will be raised
    #
    # @return [StrongParameters] the strong params in the `data` param
    def data_params
      if @data.blank?
        @data = params.require('data')
        raise RequestDocumentInvalidError.new(field: :base) if @data.is_a?(Array)
      end

      @data
    end

    # Requires the data param, with only resource identifiers permitted
    #
    # @return [StrongParameters] the resource identifiers in the `data` param
    def resource_identifier_data_params
      params.permit(data: [:id, :type]).require('data')
    end

    # An array of symbols stating params that are permitted for a #create action
    #   for a record
    #
    # @note Abstract function, must be overridden by every controller
    #
    # @return [Array] a list of params permitted to create a record of whatever type
    #   a given controller manages
    def permitted_create_params
      fail NotImplementedError
    end

    # An array of symbols stating params that are permitted for a #update action
    #   for a record
    #
    # @note Abstract function, must be overridden by every controller
    #
    # @return [Array] a list of params permitted to update a record of whatever type
    #   a given controller manages
    def permitted_update_params
      fail NotImplementedError
    end

    # Gets the permitted params for a given action (create, update)
    #
    # @param [Symbol] action the action to get permitted params for
    # @return [Array] the permitted params for a given action
    def permitted_params_for(action)
      send("permitted_#{action}_params")
    end

    # Gets a set of nested params in an action_params definition
    #
    # @example
    #   create_params => [:body, user: [:name, :email]]
    #   nested_params_for(user, create_params)
    #     => [:name, :email]
    #
    # @param [Symbol] key the key of the nested params
    # @param [Array] params the params to search for the key in
    # @return [Array,Nil] the nested params for a given key
    def nested_params_for(key, params)
      key = key.to_sym
      params.detect { |p| p.is_a?(Hash) && p.has_key?(key) }.try(:[], key)
    end

    # Flattens an array of the top level keys for a given set of params
    #
    # @example
    #   create_params => [:body, user: [:name], post: [:title]]
    #   flattened_keys_for(create_params) => [:body, :user, :post]
    #
    # @param [Array] params the params to flatten keys for
    # @return [Array] the flattened array of keys for the action params
    def flattened_keys_for(params)
      params.map do |p|
        if p.is_a?(Hash)
          p.keys
        else
          p
        end
      end.flatten
    end

    # Builds permitted attributes and relationships into the queried record
    #
    # @example
    #   params = {
    #     type: 'orders',
    #     attributes: { price: '...', other: '...' },
    #     relationships: {
    #       product: {
    #         data: { token: 'asj38k', type: 'products' }
    #       }
    #     }
    #   }
    #   create_params => [:price]
    #
    #   assign_changes_from_document(record, params, create_params)
    #     => { price: '...', product: Product<@token='asj38k'> }
    #
    # @example
    #   params = {
    #     type: 'orders',
    #     attributes: { price: '...', other: '...' },
    #     relationships: {
    #       order_items: {
    #         data: [{
    #           type: 'order_items',
    #           attributes: {
    #             title: 'An order item',
    #             amount: 5.0,
    #             tax: 0.0
    #           }
    #         }]
    #       }
    #     }
    #   }
    #
    #   create_params => [:price, order_items: [:title, :amount, :tax]]
    #
    #   assign_changes_from_document(record, params, create_params) # => {
    #     price: '...',
    #     order_items: [OrderItem<@token=nil,@title='An order item',@amount=5.0,@tax=0.0>]
    #   }
    #
    # @param [ActiveRecord::Base] record the record to build attribute into
    # @param [Parameters] data the data sent to the server to construct and assign to the record
    # @param [Array] permitted_params the permitted params for the action
    # @option [String] parent_relationship_name the parent relationship assigning these attributes to the record, used to determine
    #   engaged aliases @see concerns/aliasing
    def assign_changes_from_document(record, data, permitted_params = [], parent_relationship_name: nil)
      # TODO: Make safe by enforcing that only a single alias/unalias can be engaged at once
      aliases_document =
        if parent_relationship_name
          engaged_field_aliases[parent_relationship_name] ||= {}
        else
          engaged_field_aliases
        end

      if data[:attributes]
        assign_fields_to_record record, extract_attributes_from_document(
          record,
          data[:attributes],
          permitted_params,
          aliases_document
        )
      end

      if data[:relationships]
        collection_relationships, singular_relationships =
          flattened_keys_for(permitted_params)
          .select { |k|
            begin
              record.association(actual_field(k, record.class))
            rescue ActiveRecord::AssociationNotFoundError
              false
            end
          }
          .partition { |k| record.association(actual_field(k, record.class)).reflection.collection? }
          .map { |s|
            s.map { |r| permitted_params.include?(r) ? r : { r => nested_params_for(r, permitted_params) } }
          }

        assign_fields_to_record record, extract_relationships_from_document(
          record,
          data[:relationships],
          singular_relationships,
          aliases_document
        )

        assign_fields_to_record record, extract_relationships_from_document(
          record,
          data[:relationships],
          collection_relationships,
          aliases_document
        )
      end
    end

    # Assigns fields to the record conditionally based on whether or not assign_attributes is available
    # @note Allows non-ActiveRecord models to be handled
    #
    # @param [ActiveRecord::Base,Struct] record the record to assign fields to
    # @param [Hash] fields the fields to assign to the record
    def assign_fields_to_record(record, fields)
      if record.respond_to?(:assign_attributes)
        record.assign_attributes(fields)
      else
        fields.each { |k, v| record.send("#{k}=", v) }
      end
    end

    # Builds an object of attributes to assign to a record, based on a document
    #
    # @param [ActiveRecord] record the record corresponding to the data document
    # @param [Parameters] data the document to extract attributes from
    # @param [Array<Symbol,Hash>] permitted_params the permitted attributes that can be assigned through this controller
    # @param [Hash] aliases_document the aliases document reflects usage of aliases in the data document
    # @return [Hash] the object of attributes to assign to the record
    def extract_attributes_from_document(record, data, permitted_params, aliases_document)
      data
      .slice(*permitted_params)
      .each_with_object({}) do |(attribute_name, val), attributes|
        attribute_name = attribute_name.to_sym
        actual_attribute_name = actual_field(attribute_name, record.class)

        if attribute_name != actual_attribute_name
          aliases_document[attribute_name] = true
        end

        attributes[actual_attribute_name] = val
      end
    end

    # Builds an object of relationships to assign to a record, based on a document
    #
    # @param [ActiveRecord] record the record corresponding to the data document
    # @param [Parameters] data the document to extract relationships from
    # @param [Array<Symbol,Hash>] permitted_relationships the permitted relationships that can be assigned through this controller
    # @param [Hash] aliases_document the aliases document reflects usage of aliases in the data document
    # @return [Hash] the object of relationships to assign to the record
    def extract_relationships_from_document(record, data, permitted_relationships, aliases_document)
      data
      .slice(*flattened_keys_for(permitted_relationships))
      .each_with_object({}) do |(relationship_name, relationship_data), relationships|
        relationship_name = relationship_name.to_sym
        actual_relationship_name = actual_field(relationship_name, record.class)

        if relationship_name != actual_relationship_name
          aliases_document[relationship_name] = {}
        end

        begin
          raise RequestDocumentInvalidError.new(field: :base) unless relationship_data.has_key?(:data)

          relationship_result = records_for_relationship(
            record,
            nested_params_for(relationship_name, permitted_relationships),
            relationship_name,
            relationship_data[:data]
          )

          reflection = record.association(actual_relationship_name).reflection
          if (reflection.collection? && !relationship_result.is_a?(Array)) ||
            (!reflection.collection? && relationship_result.is_a?(Array))

            raise RequestDocumentInvalidError.new(field: :base)
          end

          if record.persisted? && reflection.collection? &&
            (inverse_reflection = record.class.reflect_on_association(actual_relationship_name).inverse_of)

            relationship_result.each { |r| r.send("#{inverse_reflection.name}=", record) }
            invalid_results = relationship_result.reject(&:valid?)
            raise RecordInvalidError.new(invalid_results.first) if invalid_results.any?
          end

          relationships[actual_relationship_name] = relationship_result
        rescue Caprese::RecordNotFoundError => e
          record.errors.add(relationship_name, :not_found, t: e.t.slice(:value))
        rescue RecordInvalidError => e
          propagate_errors_to_parent(
            record,
            relationship_name,
            e.record.errors.to_a
          )
        rescue RequestDocumentInvalidError => e
          propagate_errors_to_parent(
            record,
            relationship_name,
            [e]
          )
        end
      end
    end

    # Gets all the records for a relationship given a relationship data definition
    #
    # @param [ActiveRecord] owner the owner of the relationship
    # @param [Array] permitted_params the permitted params for the
    # @param [String] relationship_name the name of the relationship to get records for
    # @param [Hash,Array<Hash>] relationship_data the resource identifier data to use to find/build records
    # @return [ActiveRecord,Array<ActiveRecord>] the record(s) for the relationship
    def records_for_relationship(owner, permitted_params, relationship_name, relationship_data)
      result = Array.wrap(relationship_data).map do |relationship_data_item|
        ref = record_for_resource_identifier(relationship_data_item)

        if ref && contains_constructable_data?(relationship_data_item)
          assign_changes_from_document(ref, relationship_data_item, permitted_params, parent_relationship_name: relationship_name)
          propagate_errors_to_parent(owner, relationship_name, ref.errors.to_a) if ref.errors.any?
        end

        ref
      end

      relationship_data.is_a?(Array) && result || result.first
    end

    # Indicates whether or not :attributes or :relationships keys are in a resource identifier,
    # thus allowing us to construct this data into the final record
    #
    # @param [Hash] resource_identifier the resource identifier to check for constructable data in
    # @return [Boolean] whether or not the resource identifier contains constructable data
    def contains_constructable_data?(resource_identifier)
      [:attributes, :relationships].any? { |k| resource_identifier.key?(k) }
    end

    # Propagates errors to parent with nested field name
    #
    # @param [ActiveRecord] parent the parent to propagate errors to
    # @param [String] relationship_name the name to use when nesting the errors
    # @param [Array<Error>] errors the errors to propagate
    def propagate_errors_to_parent(parent, relationship_name, errors)
      errors.each do |error|
        parent.errors.add(
          error.field == :base ? relationship_name : "#{relationship_name}.#{error.field}",
          error.code,
          t: error.t.except(:field, :field_title)
        )
      end
    end

    # Called in create, after the record is saved. When creating a new record, and assigning to it
    # existing has_many association relation, the records in the relation will be pushed onto the
    # appropriate target, but the relationship will not be persisted in their attributes until their
    # owner is saved.
    #
    # This methods persists the collection relation(s) pushed onto the record's association target(s)
    def persist_collection_relationships(record)
      record.class.reflect_on_all_associations
      .select { |ref| ref.collection? && !ref.through_reflection && record.association(ref.name).target.any? }
      .map do |ref|
        [
          ref.has_inverse? ? ref.inverse_of.name : ref.options[:as],
          record.association(ref.name).target
        ]
      end
      .to_h.each do |name, targets|
        targets.each { |t| t.update name => record }
      end
    end
  end
end
