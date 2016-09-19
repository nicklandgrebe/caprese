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
  end
end
