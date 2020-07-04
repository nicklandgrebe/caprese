require 'active_support/concern'
require 'caprese/errors'
require 'kaminari'

module Caprese
  module Query
    extend ActiveSupport::Concern

    included do
      before_action :execute_before_query_callbacks
      after_action  :execute_after_query_callbacks
    end

    # Standardizes the index action since it always does the same thing
    def index
      render(
        json: queried_collection,
        fields: query_params[:fields].try(:to_unsafe_hash),
        include: query_params[:include]
      )
    end

    # Standardizes the show action since it always does the same thing
    def show
      render(
        json: queried_record,
        fields: query_params[:fields].try(:to_unsafe_hash),
        include: query_params[:include]
      )
    end

    # The params that affect the query and subsequent response
    #
    # @example INCLUDE ASSOCIATED RESOURCES
    #   `GET /api/v1/products?include=merchant`
    #
    # @example INCLUDE NESTED ASSOCIATED RESOURCES
    #   `GET /api/v1/products?include=merchant.currency`
    #
    # @example FIELDSETS
    #   `GET /api/v1/products?include=merchant&fields[product]=title,description&fields[merchant]=id,name`
    #
    # @example SORT
    #   `GET /api/v1/products?sort=updated_at`
    #
    # @example SORT DESCENDING
    #   `GET /api/v1/products?sort=-updated_at`
    #
    # @example PAGINATION
    #   `GET /api/v1/products?page[number]=1&page[size]=5`
    #
    # @example LIMIT AND OFFSET
    #   `GET /api/v1/products?limit=1&offset=1`
    #
    # @example LIMIT AND OFFSET (GET LAST)
    #   `GET /api/v1/products?limit=1&offset=-1`
    #
    # @example FILTERING
    #   `GET /api/v1/products?filter[venue_id]=10`
    #
    # @return [Hash] the params that modify our query
    def query_params
      if @query_params.blank?
        @query_params = params.except(:action, :controller)

        # Sort query by column, ascending or descending
        @query_params[:sort] = @query_params[:sort].split(',') if @query_params[:sort]

        # Convert fields params into arrays for each resource
        @query_params[:fields].each do |resource, fields|
          @query_params[:fields][resource] = fields.split(',')
        end if @query_params[:fields]
      end

      @query_params
    end

    # Gets a collection of type `type`, providing the collection as
    # a `record scope` by which to query records
    #
    # @note We use the term scope, because the collection may be all records of that type,
    #   or the records may be scoped further by overriding this method
    #
    # @param [Symbol] type the type to get a record scope for
    # @return [Relation] the scope of records of type `type`
    def record_scope(type)
      record_class(type).all
    end

    # Given a resource identifier, finds or builds a resource
    #
    # @param [Hash] resource_identifier the resource identifier for the resource
    # @return [ActiveRecord::Base] the found or built resource for the relationship
    def record_for_resource_identifier(resource_identifier)
      if (type = resource_identifier[:type])
        # { type: '...', id: '...' }
        if (id = resource_identifier[:id])
          begin
            get_record!(
              type,
              Caprese.config.resource_primary_key,
              id
            )
          rescue RecordNotFoundError => e
            raise e unless record_scope(type.to_sym).is_a?(ActiveRecord::NullRelation)
          end

          # { type: '...', attributes: { ... } }
        elsif contains_constructable_data?(resource_identifier)
          record_scope(type.to_sym).build

          # { type: '...' }
        else
          raise RequestDocumentInvalidError.new(field: :base)
        end
      else
        # { id: '...' } && { attributes: { ... } }
        raise RequestDocumentInvalidError.new(field: :type)
      end
    end

    # Gets a record in a scope using a column/value to search by
    #
    # @example
    #   get_record(:orders, :id, '1e0da61f-0229-4035-99a5-3e5c37a221fb')
    #     # => Order.find_by(id: '1e0da61f-0229-4035-99a5-3e5c37a221fb')
    #
    # @param [Symbol,Relation] scope the scope to find the record in
    #   if Symbol, call record_scope for that type and use it
    #   if Relation, use it as a scope
    # @param [Symbol] column the name of the column to find the record by
    # @param [Value] value the value to match to a column/row value
    # @return [APIRecord] the record that was found
    def get_record(scope, column, value)
      scope = record_scope(scope.to_sym) unless scope.respond_to?(:find_by)

      scope.find_by(column => value) unless scope.empty?
    end

    # Gets a record in a scope using a column/value to search by
    # @note Fails with error 404 Not Found if the record was not found
    #
    # @see get_record
    def get_record!(scope, column, value)
      scope = record_scope(scope.to_sym) unless scope.respond_to?(:find_by!)

      begin
        scope.find_by!(column => value) unless scope.is_a?(Array) && scope.empty?
      rescue ActiveRecord::RecordNotFound => e
        fail RecordNotFoundError.new(
          model: scope.name.underscore,
          value: value
        )
      end
    end

    # Applies query_params[:sort] and query_params[:page] to a given scope
    #
    # @param [Relation] scope the scope to apply sorting and pagination to
    # @return [Relation] the sorted and paginated scope
    def apply_sorting_pagination_to_scope(scope)
      return scope if scope.empty?

      if query_params[:sort].try(:any?)
        ordering = {}
        query_params[:sort].each do |sort_field|
          ordering = ordering.merge(
            if sort_field[0] == '-' # EX: -created_at, sort by created_at descending
              { actual_field(sort_field[1..-1]) => :desc }
            else
              { actual_field(sort_field) => :asc }
            end
          )
        end
        scope = scope.reorder(ordering)
      end

      if query_params[:offset] || query_params[:limit]
        offset = query_params[:offset].to_i || 0

        if offset < 0
          offset = scope.count + offset
        end

        limit = query_params[:limit] && query_params[:limit].to_i || Caprese.config.default_page_size
        limit = [limit, Caprese.config.max_page_size].min

        scope.offset(offset).limit(limit)
      else
        page_number = query_params[:page].try(:[], :number)
        page_size = query_params[:page].try(:[], :size).try(:to_i) || Caprese.config.default_page_size
        page_size = [page_size, Caprese.config.max_page_size].min

        scope.page(page_number).per(page_size)
      end
    end

    # Gets the scope by which to query controller records, taking into account custom scoping and
    # the filters provided in the query
    #
    # @return [Relation] the record scope of the queried controller
    def queried_record_scope
      unless @queried_record_scope
        scope = record_scope(unnamespace(params[:controller]).to_sym)

        if scope.any? && query_params[:filter] && !query_params[:filter].empty?
          if (valid_filters = query_params[:filter].select { |k, _| scope.column_names.include? actual_field(k).to_s }).present?
            valid_filters.each do |k, v|
              scope = scope.where(actual_field(k) => v)
            end
          end
        end

        @queried_record_scope = scope
      end

      @queried_record_scope
    end

    # Gets the record that was queried, i.e. the record corresponding to the primary key in the
    # route param (/:id), in the queried_record_scope
    #
    # @return [ActiveRecord::Base] the queried record
    def queried_record
      @queried_record ||=
        get_record!(
          queried_record_scope,
          Caprese.config.resource_primary_key,
          params[:id]
        )
    end

    # Gets the collection that was queried, i.e. the sorted & paginated queried_record_scope
    #
    # @return [Relation] the queried collection
    def queried_collection
      @queried_collection ||= apply_sorting_pagination_to_scope(queried_record_scope)
    end
  end
end
