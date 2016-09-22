require 'caprese/controller'
require 'caprese/record'
require 'caprese/routing/caprese_resources'
require 'caprese/serializer'
require 'caprese/version'

module Caprese
  def self.config
    Controller.config
  end

  # Defines the primary key to use when querying records
  config.resource_primary_key ||= :id

  # Defines the ActiveModelSerializers adapter to use when serializing
  config.adapter ||= :json_api

  # Define URL options for use in UrlHelpers
  config.default_url_options ||= {}

  # If true, links will be rendered as `only_path: true`
  # TODO: Implement this
  config.only_path_links ||= true

  # If true, relationship data will not be serialized unless it is in `include`
  config.optimize_relationships ||= true

  # Defines the translation scope for model and controller errors
  config.i18n_scope ||= '' # 'api.v1.errors'

  # The default size of any page queried
  config.default_page_size ||= 10

  # The maximum size of any page queried
  config.max_page_size ||= 100
end
