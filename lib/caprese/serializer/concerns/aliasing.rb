require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    # TODO: Modify so we specify aliased attributes/relationships in the serializer, and those aliases
    #   map to the actual field names' values when serialized
    module Aliasing
      extend ActiveSupport::Concern

      included do

      end
    end
  end
end
