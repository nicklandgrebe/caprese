require 'action_dispatch/routing/mapper/resources'

module Caprese
  module Routing
    module CapreseResources
      extend ActionDispatch::Routing::Mapper::Resources

      def caprese_resources(*resources, &block)
        options = resources.extract_options!.dup

        if apply_common_behavior_for(:resources, resources, options, &block)
          return self
        end

        resource_scope(:resources, Resource.new(resources.pop, options)) do
          yield if block_given?

          concerns(options[:concerns]) if options[:concerns]

          collection do
            get  :index if parent_resource.actions.include?(:index)
            post :create if parent_resource.actions.include?(:create)
          end

          member do
            get 'relationships/:relationship',
              to: "#{parent_resource.name}#get_relationship_definition",
              as: :relationship_definition

            match 'relationships/:relationship',
              to: "#{parent_resource.name}#update_relationship_definition",
              via: [:patch, :post, :delete]

            get ':relationship(/:relation_primary_key_value)',
              to: "#{parent_resource.name}#get_relationship_data",
              as: :relationship_data
          end

          new do
            get :new
          end if parent_resource.actions.include?(:new)

          set_member_mappings_for_resource
        end

        self
      end
    end
  end
end
