require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    module Lookup
      extend ActiveSupport::Concern

      module ClassMethods
        # Gets a versioned serializer for a given record
        #
        # @note Overrides the default since the default does not do namespaced lookup
        #
        # @param [ActiveRecord::Base] record the record to get a serializer for
        # @param [Hash] options options for `super` to use when getting the serializer
        # @return [Serializer,Nil] the serializer for the given record
        def serializer_for(record, options = {})
          get_serializer_for(record.class) || super
        end

        private

        # Gets a serializer for a klass, either as the serializer explicitly defined
        # for this class, or as a serializer defined for one of the klass's parents
        #
        # @param [Class] klass the klass to get the serializer for
        # @return [Serializer] the serializer for the class
        def get_serializer_for(klass)
          begin
            version_module("#{klass.name}Serializer").constantize
          rescue NameError => e
            get_serializer_for(klass.superclass) if klass.superclass
          end
        end
      end
    end
  end
end
