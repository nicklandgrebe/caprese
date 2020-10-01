require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    module Relationships
      extend ActiveSupport::Concern

      # Applies further scopes to a singular or collection association when rendered as part of included document
      # @note Can be overridden to customize scoping at a per-relationship level
      #
      # @example
      #   def relationship_scope(name, scope)
      #     case name
      #     when :transactions
      #       scope.by_merchant(...)
      #     when :orders
      #       scope.by_user(...)
      #     when :user
      #       # change singular user response
      #     end
      #   end
      #
      # @param [String] name the name of the association
      # @param [Relation,Record] scope the scope corresponding to a collection association relation or singular record
      def relationship_scope(name, scope)
        scope
      end

      module ClassMethods
        def has_many(name, options = {}, &block)
          super(
            name,
            merge_serializer_option(name, options),
            &build_association_block(name)
          )
        end

        def has_one(name, options = {}, &block)
          super(
            name,
            merge_serializer_option(name, options),
            &build_association_block(name)
          )
        end

        def belongs_to(name, options = {}, &block)
          super(
            name,
            merge_serializer_option(name, options),
            &build_association_block(name)
          )
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
          reflection_name = reflection_name.to_sym

          Proc.new do |serializer|
            if Caprese.config.relationship_links
              link :self do
                url = "relationship_definition_#{serializer.version_name("#{serializer.unnamespace(object.class.name).underscore}_url")}"
                if serializer.url_helpers.respond_to? url
                  serializer.url_helpers.send(
                    url,
                    id: object.read_attribute(Caprese.config.resource_primary_key),
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
                    id: object.read_attribute(Caprese.config.resource_primary_key),
                    relationship: reflection_name,
                    host: serializer.class.send(:caprese_default_url_options_host)
                  )
                end
              end
            end

            serializer.relationship_scope(
              reflection_name,
              serializer.read_attribute_for_serialization(object.class.caprese_unalias_field(name))
            )
          end
        end

        # Adds a default serializer for relationship based on the relationship name
        #
        # @example
        #   has_many :answers => AnswerSerializer
        #
        # @param [String] name the name of the relationship
        # @param [Hash] options options to add default serializer to
        # @return [Hash] the default options
        def merge_serializer_option(name, options)
          { serializer: get_serializer_for(name.to_s.classify) }.merge(options)
        end
      end
    end
  end
end
