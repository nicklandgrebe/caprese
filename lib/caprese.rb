require 'caprese/controller'
require 'caprese/record'
require 'caprese/routing/caprese_resources'
require 'caprese/serializer'
require 'caprese/version'
require 'caprese/app/models/current'

module Caprese
  def self.config
    Controller.config
  end

  # Defines the primary key to use when querying records
  config.resource_primary_key ||= :id

  # Defines the ActiveModelSerializers adapter to use when serializing
  config.adapter ||= :json_api

  # Defines the full Content-Type header to respond with
  # @note Caprese accepts both application/json and application/vnd.api+json
  config.content_type = 'application/vnd.api+json; charset=utf-8'

  # Define URL options for use in UrlHelpers
  config.default_url_options ||= {}

  # If true, links will be rendered as `only_path: true`
  # TODO: Implement this
  config.only_path_links ||= true

  # If true, relationship data will not be serialized unless it is in `include`
  config.optimize_relationships ||= false

  # Defines the translation scope for model and controller errors
  config.i18n_scope ||= '' # 'api.v1.errors'

  # The default size of any page queried
  config.default_page_size ||= 10

  # The maximum size of any page queried
  config.max_page_size ||= 100

  # If true, Caprese will trim the isolated namespace module of the engine off the front of output
  #   from methods contained in Versioning module
  config.isolated_namespace ||= nil
end
