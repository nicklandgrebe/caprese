require 'caprese/configuration'
require 'caprese/controller'
require 'caprese/record'
require 'caprese/routing/caprese_resources'
require 'caprese/serializer'
require 'caprese/version'
require 'caprese/app/models/current'

module Caprese
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end
