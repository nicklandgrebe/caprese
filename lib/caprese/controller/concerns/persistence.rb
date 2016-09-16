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
    #
    # 1. Check that type of record to be created matches type that the given controller manages
    # 2. Build the appropriate attributes/associations for the create action
    # 3. Build a record with the attributes
    # 4. Execute after_initialize callbacks
    # 5. Execute before_create callbacks
    # 6. Execute before_save callbacks
    # 7. Create the record by saving it (or fail with RecordInvalid and render errors)
    # 8. Execute after_create callbacks
    # 9. Execute after_save callbacks
    # 10. Return the created resource with 204 Created
    #    @see #rescue_from ActiveRecord::RecordInvalid
    def create
      fail_on_type_mismatch(data_params[:type])

      resource = queried_record_scope.build(build_attributes(:create))
      execute_after_initialize_callbacks(resource)

      execute_before_create_callbacks(resource)
      execute_before_save_callbacks(resource)

      resource.save!

      execute_after_create_callbacks(resource)
      execute_after_save_callbacks(resource)

      render(
        json: resource,
        status: :created,
        fields: query_params[:fields],
        include: query_params[:include]
      )
    end

    # Updates a record of whatever type a given controller manages
    #
    # @note For this action to succeed, the given controller must define `update_params`
    #   @see #update_params
    #
    # 1. Check that type of record to be updated matches type that the given controller manages
    # 2. Execute before_update callbacks
    # 3. Execute before_save callbacks
    # 4. Update the record (or fail with RecordInvalid and render errors)
    # 5. Execute after_update callbacks
    # 6. Execute after_save callbacks
    # 7. Return the updated resource
    #    @see #rescue_from ActiveRecord::RecordInvalid
    def update
      fail_on_type_mismatch(data_params[:type])

      execute_before_update_callbacks(queried_record)
      execute_before_save_callbacks(queried_record)

      queried_record.update!(build_attributes(:update))

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
    def create_params
      fail NotImplementedError
    end

    # An array of symbols stating params that are permitted for a #update action
    #   for a record
    #
    # @note Abstract function, must be overridden by every controller
    #
    # @return [Array] a list of params permitted to update a record of whatever type
    #   a given controller manages
    def update_params
      fail NotImplementedError
    end

    # Using a resource_identifier, finds or builds a resource for a relationship
    #
    # @example
    #   resource_identifier = { type: 'order_items', token: 'as929a22' }
    #   build_relationship_resource(:order_items, :create, resource_identifier)
    #   # => OrderItem<@token='as929a22'>
    #
    # @example
    #   create_params = [..., order_items: [:title, :amount, :tax]]
    #   resource_identifier = { type: 'order_items', attributes: { title: 'Title', amount: 5.0 } }
    #   build_relationship_resource(:order_items, :create, resource_identifier)
    #   # => OrderItem<@token=nil, @title='Title', @amount=5.0>
    #
    # @param [String] name the name of the relationship
    # @param [String] action the name of the action that is being performed (create, update)
    # @param [Hash] resource_identifier the resource identifier for the resource
    # @return [ActiveRecord::Base] the found or built resource for the relationship
    #
    # 1. If there is a token in the resource identifier, find the resource with that ID
    # 2. If there are attributes, build a new record of the type specified in the request
    # 3. If there is neither a token nor attributes, the resource identifier is invalid
    # 4. Assign the attributes permitted for the action to the relationship record
    # 5. Return the found/built resource
    def build_relationship_resource(name, action, resource_identifier)
      type = resource_identifier[:type]
      attributes = resource_identifier[:attributes]

      resource =
        if (token = resource_identifier[:token])
          get_record!(type, :token, token)
        elsif attributes
          record_scope(type).build
        else
          fail Error.new(field: name, code: :invalid)
        end

      if attributes
        resource.assign_attributes(
          attributes.permit(
            *send("#{action}_params")
            .detect { |p| p.try(:keys).try(:[], 0) == name.to_sym }
            .try(:values)
            .try(:[], 0)
          )
        )
      end

      resource
    end

    # Builds an attributes object to persist in a record, with attributes and relationships included
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
    #   build_attributes(:create) => { price: '...', product: Product<@token='asj38k'> }
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
    #   build_attributes(:create) # => {
    #     price: '...',
    #     order_items: [OrderItem<@token=nil,@title='An order item',@amount=5.0,@tax=0.0>]
    #   }
    #
    # @param [Symbol] action the action to build attributes for (determines which params object we use):
    #   create_params, update_params, etc.
    # @return [Hash] the built attributes to persist in a record
    #
    # 1. Create an attributes hash from the attributes of the data sent in
    # 2. Iterate over each relationship specified in the data object, adding each to the attributes hash
    #    as a built resource (either a persisted resource found by token, or a new resource created with attributes
    #    defined in the resource identifier)
    # 3. Return attributes hash, scoped to only those permitted by `#{action}_params`
    def build_attributes(action)
      attributes = data_params[:attributes]
      data_params[:relationships].try(:each) do |name, relationship|
        attributes[name] =
          if (relationship_data = relationship[:data]).is_a?(Array)
            relationship_data.map do |resource_identifier|
              build_relationship_resource(name, action, resource_identifier)
            end
          else
            build_relationship_resource(name, action, relationship_data)
          end
      end

      attributes.permit(*send("#{action}_params"))
    end
  end
end
