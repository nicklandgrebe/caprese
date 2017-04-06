require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    module Aliasing
      extend ActiveSupport::Concern

      # Override so we can get the values for serialization of aliased attributes just like unaliased
      #
      # @param [String,Symbol] attribute the attribute (aliased or not) to read for serialization
      # @return [Value] the value of the attribute
      def read_attribute_for_serialization(attribute)
        super(self.object.class.caprese_unalias_field(attribute))
      end
    end
  end
end
