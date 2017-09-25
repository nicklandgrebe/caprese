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
          if object.persisted? && (url = serializer.class.route_for(object))
            serializer.url_helpers.send(
              url,
              object.read_attribute(Caprese.config.resource_primary_key),
              host: serializer.class.send(:caprese_default_url_options_host)
            )
          end
        end
      end

      module ClassMethods
        # Fetches the host from Caprese.config.default_url_options or fails if it is not set
        # @note default_url_options[:host] is used to render the host in links that are serialized in the response
        def caprese_default_url_options_host
          Caprese.config.default_url_options.fetch(:host) do
            fail 'Caprese requires that config.default_url_options[:host] be set when rendering links.'
          end
        end

        # Overridden so we can define relationship links without any code in a specific
        # serializer
        def has_many(name, options = {}, &block)
          super name, options, &build_association_block(name)

          define_method name do
            self.relationship_scope(name, object.send(name))
          end
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

          reflection_name = reflection_name.to_sym

          Proc.new do |serializer|
            if object.persisted?
              link :self do
                url = "relationship_definition_#{serializer.version_name("#{serializer.unnamespace(object.class.name).underscore}_url")}"
                if serializer.url_helpers.respond_to? url
                  serializer.url_helpers.send(
                    url,
                    id: object.read_attribute(primary_key),
                    relationship: reflection_name,
                    host: serializer.class.send(:caprese_default_url_options_host)
                  )
                end
              end

              link :related do
                url = "relationship_data_#{serializer.version_name("#{serializer.unnamespace(object.class.name).underscore}_url")}"
                if serializer.url_helpers.respond_to? url
                  serializer.url_helpers.send(
                    url,
                    id: object.read_attribute(primary_key),
                    relationship: reflection_name,
                    host: serializer.class.send(:caprese_default_url_options_host)
                  )
                end
              end
            end

            :nil
          end
        end
      end
    end
  end
end
