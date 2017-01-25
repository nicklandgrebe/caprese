require 'active_model_serializers'
require 'caprese/concerns/versioning'
require 'caprese/serializer/concerns/links'
require 'caprese/serializer/concerns/lookup'

module Caprese
  class Serializer < ActiveModel::Serializer
    extend Versioning
    include Versioning
    include Links
    include Lookup

    def json_key
      unversion(self.class.name).gsub('Serializer', '').underscore
    end
  end
end
