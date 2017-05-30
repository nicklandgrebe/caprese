require 'active_model_serializers'
require 'caprese/concerns/url_helpers'
require 'caprese/concerns/versioning'
require 'caprese/serializer/concerns/aliasing'
require 'caprese/serializer/concerns/links'
require 'caprese/serializer/concerns/lookup'
require 'caprese/serializer/concerns/relationships'

module Caprese
  class Serializer < ActiveModel::Serializer
    extend UrlHelpers
    extend Versioning
    include UrlHelpers
    include Versioning
    include Aliasing
    include Links
    include Lookup
    include Relationships

    def json_key
      object.class.caprese_type
    end
  end
end
