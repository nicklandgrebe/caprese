module Caprese
  class Configuration
    attr_accessor(
      :adapter,
      :content_type,
      :default_page_size,
      :default_url_options,
      :i18n_scope,
      :isolated_namespace,
      :max_page_size,
      :only_path_links,
      :optimize_relationships,
      :relationship_links,
      :resource_primary_key
    )

    def initialize
      # Defines the primary key to use when querying records
      @resource_primary_key = :id

      # Defines the ActiveModelSerializers adapter to use when serializing
      @adapter = :json_api

      # Defines the full Content-Type header to respond with
      # @note Caprese accepts both application/json and application/vnd.api+json
      @content_type = 'application/vnd.api+json; charset=utf-8'

      # Define URL options for use in UrlHelpers
      @default_url_options = {}

      # If true, links will be rendered as `only_path: true`
      # TODO: Implement this
      @only_path_links = true

      # If true, relationship data will not be serialized unless it is in `include`
      @optimize_relationships = false

      # If true, relationship links will be serialized
      @relationship_links = true

      # Defines the translation scope for model and controller errors
      @i18n_scope = '' # 'api.v1.errors'

      # The default size of any page queried
      @default_page_size = 10

      # The maximum size of any page queried
      @max_page_size = 100

      # If true, Caprese will trim the isolated namespace module of the engine off the front of output
      #   from methods contained in Versioning module
      @isolated_namespace = nil
    end
  end
end
