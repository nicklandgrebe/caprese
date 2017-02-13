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
        rescue_with_handler Error.new(
          field: e.param,
          code: :blank
        )
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        rescue_with_handler RecordInvalidError.new(e.record)
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

      record = queried_record_scope.build
      assign_record_attributes(record, permitted_params_for(:create), data_params)

      execute_after_initialize_callbacks(record)

      execute_before_create_callbacks(record)
      execute_before_save_callbacks(record)

      fail RecordInvalidError.new(record) if record.errors.any?

      record.save!

      persist_collection_relationships(record)

      execute_after_create_callbacks(record)
      execute_after_save_callbacks(record)

      render(
        json: record,
        status: :created,
        fields: query_params[:fields],
        include: query_params[:include]
      )
    end

    # Updates a record of whatever type a given controller manages
    #
    # @note For this action to succeed, the given controller must define `update_params`
    #   @see #update_params
    def update
      fail_on_type_mismatch(data_params[:type])

      assign_record_attributes(queried_record, permitted_params_for(:update), data_params)

      execute_before_update_callbacks(queried_record)
      execute_before_save_callbacks(queried_record)

      fail RecordInvalidError.new(queried_record) if queried_record.errors.any?

      queried_record.save!

      execute_after_update_callbacks(queried_record)
      execute_after_save_callbacks(queried_record)

      render(
        json: queried_record,
        fields: query_params[:fields],
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
    #
    # @return [StrongParameters] the strong params in the `data` object param
    def data_params
      params.require('data')
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
      params.detect { |p| p.is_a?(Hash) }.try(:[], key.to_sym)
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
    #   assign_record_attributes(record, create_params, params)
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
    #   assign_record_attributes(record, create_params, params) # => {
    #     price: '...',
    #     order_items: [OrderItem<@token=nil,@title='An order item',@amount=5.0,@tax=0.0>]
    #   }
    #
    # @param [ActiveRecord::Base] record the record to build attribute into
    # @param [Array] permitted_params the permitted params for the action
    # @param [Parameters] data the data sent to the server to construct and assign to the record
    def assign_record_attributes(record, permitted_params, data)
      attributes = data[:attributes].try(:permit, *permitted_params) || {}

      data[:relationships]
      .try(:slice, *flattened_keys_for(permitted_params))
      .try(:each) do |relationship_name, relationship_data|
        attributes[relationship_name] = records_for_relationship(
          record,
          nested_params_for(relationship_name, permitted_params),
          relationship_name,
          relationship_data
        )
      end

      record.assign_attributes(attributes)
    end

    # Gets all the records for a relationship given a relationship data definition
    #
    # @param [ActiveRecord::Base] owner the owner of the relationship
    # @param [Array] permitted_params the permitted params for the
    # @param [String] relationship_name the name of the relationship to get records for
    # @param [Hash,Array<Hash>] relationship_data the resource identifier data to use to find/build records
    # @return [ActiveRecord::Base,Array<ActiveRecord::Base>] the record(s) for the relationship
    def records_for_relationship(owner, permitted_params, relationship_name, relationship_data)
      if relationship_data[:data].is_a?(Array)
        relationship_data[:data].map do |relationship_data_item|
          ref = record_for_relationship(owner, relationship_name, relationship_data_item)

          if ref && contains_constructable_data?(relationship_data_item)
            assign_record_attributes(ref, permitted_params, relationship_data_item)
          end

          ref
        end
      else
        ref = record_for_relationship(owner, relationship_name, relationship_data[:data])

        if ref && contains_constructable_data?(relationship_data[:data])
          assign_record_attributes(ref, permitted_params, relationship_data[:data])
        end

        ref
      end
    end

    # Given a resource identifier, finds or builds a resource for a relationship
    #
    # @param [ActiveRecord::Base] owner the owner of the relationship record
    # @param [String] relationship_name the name of the relationship
    # @param [Hash] resource_identifier the resource identifier for the resource
    # @return [ActiveRecord::Base] the found or built resource for the relationship
    def record_for_relationship(owner, relationship_name, resource_identifier)
      if resource_identifier[:type]
        # { type: '...', id: '...' }
        if (id = resource_identifier[:id])
          get_record!(
            resource_identifier[:type],
            Caprese.config.resource_primary_key,
            id
          )

        # { type: '...', attributes: { ... } }
        elsif contains_constructable_data?(resource_identifier)
          record_scope(resource_identifier[:type].to_sym).build

        # { type: '...' }
        else
          owner.errors.add(relationship_name)
          nil
        end
      else
        # { id: '...' } && { attributes: { ... } }
        owner.errors.add("#{relationship_name}.type")
        nil
      end
    end

    # Assigns permitted attributes for a record in a relationship, for a given action
    # like create/update
    #
    # @param [ActiveRecord::Base] record the relationship record
    # @param [String] relationship_name the name of the relationship
    # @param [Symbol] action the action that is calling this method (create, update)
    # @param [Hash] resource_identifier the resource identifier
    def assign_relationship_record_attributes(record, relationship_name, action, attributes)
      record.assign_attributes(
        attributes.permit(nested_permitted_params_for(action, relationship_name))
      )
    end

    # Indicates whether or not :attributes or :relationships keys are in a resource identifier,
    # thus allowing us to construct this data into the final record
    #
    # @param [Hash] resource_identifier the resource identifier to check for constructable data in
    # @return [Boolean] whether or not the resource identifier contains constructable data
    def contains_constructable_data?(resource_identifier)
      [:attributes, :relationships].any? { |k| resource_identifier.key?(k) }
    end

    # Called in create, after the record is saved. When creating a new record, and assigning to it
    # existing has_many association relation, the records in the relation will be pushed onto the
    # appropriate target, but the relationship will not be persisted in their attributes until their
    # owner is saved.
    #
    # This methods persists the collection relation(s) pushed onto the record's association target(s)
    def persist_collection_relationships(record)
      record.class.reflect_on_all_associations
      .select { |ref| ref.collection? && !ref.through_reflection && record.association(ref.name).any? }
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
