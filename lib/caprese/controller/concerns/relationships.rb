require 'active_support/concern'
require 'caprese/errors'

module Caprese
  module Relationships
    extend ActiveSupport::Concern

    # Applies further scopes to a collection association
    # @note Can be overridden to customize scoping at a per-relationship level
    #
    # @example
    #   def relationship_scope(name, scope)
    #     case name
    #     when :transactions
    #       scope.by_merchant(...)
    #     when :orders
    #       scope.by_user(...)
    #     end
    #   end
    #
    # @param [String] name the name of the association
    # @param [Relation] scope the scope corresponding to a collection association
    def relationship_scope(name, scope)
      scope
    end

    # Retrieves the data for a relationship, not just the definition/resource identifier
    #   @note Resource Identifier = { id: '...', type: '....' }
    #   @note Resource = Resource Identifier + { attributes: { ... } }
    #
    # @note Adds a links[:self] link to this endpoint itself, to be JSON API compliant
    # @note When returning single resource, adds a related endpoint URL that points to
    #   the root resource URL
    #
    # @example Order<token: 'asd27h'> with product
    #   links[:self] = 'http://www.example.com/api/v1/orders/asd27h/product'
    #   links[:related] = 'http://www.example.com/api/v1/products/h45sql'
    #
    # @example Order<token: 'asd27h'> with transactions
    #   links[:self] = 'http://www.example.com/api/v1/orders/asd27h/transactions/7ytr4l'
    #   links[:related] = 'http://www.example.com/api/v1/transactions/7ytr4l'
    #
    # GET /api/v1/:controller/:id/:relationship(/:relation_primary_key_value)
    def get_relationship_data
      target =
        if queried_association.reflection.collection?
          scope = relationship_scope(params[:relationship], queried_association.reader)

          if params[:relation_primary_key_value].present?
            get_record!(scope, self.class.config.resource_primary_key, params[:relation_primary_key_value])
          else
            apply_sorting_pagination_to_scope(scope)
          end
        else
          queried_association.reader
        end

      links = { self: request.original_url }

      if !target.respond_to?(:to_ary) &&
        Rails.application.routes.url_helpers
        .respond_to?(related_url = version_name("#{params[:relationship].singularize}_url"))

        links[:related] =
          Rails.application.routes.url_helpers.send(
            related_url,
            target.read_attribute(self.config.resource_primary_key),
            host: caprese_default_url_options_host
          )
      end

      render(
        json: target,
        fields: query_params[:fields],
        include: query_params[:include],
        links: links
      )
    end

    # Returns relationship data for a resource
    #
    # 1. Find resource we are updating relationship for
    # 2. Check relationship exists *or respond with error*
    # 3. Add self/related links for relationship
    # 4. Respond with relationship data
    #
    # @example to-one relationship
    #   GET /orders/asd27h/relationships/product
    #
    #   {
    #     "links": {
    #       "self": "/orders/asd27h/relationships/product",
    #       "related": "orders/asd27h/product"
    #     },
    #     "data": {
    #       "type": "products",
    #       "token": "hy7sql"
    #     }
    #   }
    #
    # @example to-many relationship
    #   GET /orders/1/relationships/transactions
    #
    #   {
    #     "links": {
    #       "self": "/orders/asd27h/relationships/transactions",
    #       "related": "orders/asd27h/transactions"
    #     },
    #     "data": [
    #       { "type": "transactions", "token": "hy7sql" },
    #       { "type": "transactions", "token": "lki26s" },
    #     ]
    #   }
    #
    # GET /api/v1/:controller/:id/relationships/:relationship
    def get_relationship_definition
      links = { self: request.original_url }

      # Add related link for this relationship if it exists
      if Rails.application.routes.url_helpers
        .respond_to?(related_path = "relationship_data_#{version_name(unversion(params[:controller]).singularize)}_url")

        links[:related] = Rails.application.routes.url_helpers.send(
          related_path,
          params[:id],
          params[:relationship],
          host: caprese_default_url_options_host
        )
      end

      target = queried_association.reader

      if queried_association.reflection.collection?
        target = relationship_scope(params[:relationship], target)
      end

      render(
        json: target,
        fields: {},
        include: query_params[:include],
        links: links
      )
    end

    # Updates a relationship for a resource
    #
    # 1. Find resource we are updating relationship for
    # 2. Check relationship exists *or respond with error*
    # 3. Find each potential relationship resource corresponding to the resource identifiers passed in
    # 4. Modify relationship based on relationship type (one-to-many, one-to-one) and HTTP verb (PATCH, POST, DELETE)
    # 5. Check if update was successful
    #   * If successful, return 204 No Content
    #   * If unsuccessful, return 403 Forbidden
    #
    # @example modify to-one relationship
    #   PATCH /orders/asd27h/relationships/product
    #
    #   {
    #     "data": { "type": "products", "token": "hy7sql" }
    #   }
    #
    # @example clear to-one relationship
    #   PATCH /orders/asd27h/relationships/product
    #
    #   {
    #     "data": null
    #   }
    #
    # @example modify to-many relationship
    #   PATCH /orders/asd27h/relationships/transactions
    #
    #   {
    #     "data": [
    #       { "type": "transactions", "token": "hy7sql" },
    #       { "type": "transactions", "token": "lki26s" },
    #     ]
    #   }
    #
    # @example clear to to-many relationship
    #   PATCH /orders/asd27h/relationships/transactions
    #
    #   {
    #     "data": []
    #   }
    #
    # @example append to to-many relationship
    #   POST /orders/asd27h/relationships/transactions
    #
    #   {
    #     "data": [
    #       { "type": "transactions", "token": "hy7sql" },
    #       { "type": "transactions", "token": "lki26s" },
    #     ]
    #   }
    #
    # @example remove from to-many relationship
    #   DELETE /orders/asd27h/relationships/transactions
    #
    #   {
    #     "data": [
    #       { "type": "transactions", "token": "hy7sql" },
    #       { "type": "transactions", "token": "lki26s" },
    #     ]
    #   }
    #
    # PATCH/POST/DELETE /api/v1/:controller/:id/relationships/:relationship
    def update_relationship_definition
      if queried_association &&
        flattened_keys_for(permitted_params_for(:update)).include?(params[:relationship].to_sym)

        relationship_resources =
          Array.wrap(params[:data]).map do |resource_identifier|
            get_record!(
              resource_identifier[:type],
              column = self.config.resource_primary_key,
              resource_identifier[column]
            )
          end

        relationship_name = queried_association.reflection.name

        successful =
          case queried_association.reflection.macro
          when :has_many
            if request.patch?
              queried_record.send("#{relationship_name}=", relationship_resources)
            elsif request.post?
              queried_record.send(relationship_name).push relationship_resources
            elsif request.delete?
              queried_record.send(relationship_name).delete relationship_resources
            end
          when :has_one
            if request.patch?
              queried_record.send("#{relationship_name}=", relationship_resources[0])
              objects[0].save
            end
          when :belongs_to
            if request.patch?
              queried_record.send("#{relationship_name}=", relationship_resources[0])
              queried_record.save
            end
          end
      else
        successful = false
      end

      if successful
        head :no_content
      else
        fail ActionForbiddenError.new
      end
    end

    private

    # Gets the association queried by the relationship call
    #
    # @note Fails with 404 Not Found if association cannot be found
    def queried_association
      unless @queried_association
        begin
          @queried_association = queried_record.association(actual_field(params[:relationship]))
        rescue ActiveRecord::AssociationNotFoundError => e
          fail AssociationNotFoundError.new(params[:relationship])
        end
      end

      @queried_association
    end

    # Fetches the host from Caprese.config.default_url_options or fails if it is not set
    # @note default_url_options[:host] is used to render the host in links that are serialized in the response
    def caprese_default_url_options_host
      Caprese.config.default_url_options.fetch(:host) do
        fail 'Caprese requires that config.default_url_options[:host] be set when rendering links.'
      end
    end
  end
end
