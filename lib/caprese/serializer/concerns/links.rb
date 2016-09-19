require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    module Links
      extend ActiveSupport::Concern

      included do
        # Add a links[:self] to this resource
        #
        # @example
        #   object = Order<@token='asd27h'>
        #   links = { self: '/api/v1/orders/asd27hß' }
        link :self do
          if respond_to?(url = serializer.version_name("#{object.class.name.underscore}_url"))
            send(url, object.read_attribute(Caprese.config.resource_primary_key))
          end
        end
      end

      module ClassMethods
        # Overridden so we can define relationship links without any code in a specific
        # serializer
        def has_many(name, options = {}, &block)
          super name, options, &build_association_block(name)
        end

        # @see has_many
        def has_one(name, options = {}, &block)
          super name, options, &build_association_block(name)
        end

        # @see has_many
        def belongs_to(name, options = {}, &block)
          super name, options, &build_association_block(name)
        end

        private

        # Builds a block that is passed into an association when it is defined in a specific serializer
        # The block is run, and links are added to each association so when it is rendered in the
        # `relationships` object of the `data` for record, it contains links to the particular association
        #
        # @example
        #   object = Order<@token=5, @product_id=10>
        #   reflection_name = 'product'
        #   # => {
        #     id: 'asd27h',
        #     type: 'orders',
        #     relationships: {
        #       product: {
        #         id: 'hy7sql',
        #         type: 'products',
        #         links: {
        #           self: '/api/v1/orders/asd27h/relationships/product',
        #           related: '/api/v1/orders/asd27h/product'
        #         }
        #       }
        #     }
        #   }
        #
        # @param [String] reflection_name the name of the relationship
        # @return [Block] a block to build links for the relationship
        def build_association_block(reflection_name)
          primary_key = Caprese.config.resource_primary_key

          Proc.new do |serializer|
            link :self do
              url = "relationship_definition_#{serializer.version_name("#{object.class.name.underscore}_url")}"
              if respond_to? url
                send(
                  url,
                  primary_key => object.read_attribute(primary_key),
                  relationship: reflection_name
                )
              end
            end

            link :related do
              url = "relationship_data_#{serializer.version_name("#{object.class.name.underscore}_url")}"
              if respond_to? url
                send(
                  url,
                  primary_key => object.read_attribute(primary_key),
                  relationship: reflection_name
                )
              end
            end

            :nil
          end
        end
      end
    end
  end
end
