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
  config.resource_primary_key = :id

  # Defines the ActiveModelSerializers adapter to use when serializing
  config.interface = :json_api

  # Defines the translation scope for model and controller errors
  config.i18n_scope = '' # 'api.v1.errors'
end
