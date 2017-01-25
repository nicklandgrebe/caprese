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
          return ActiveModel::Serializer::CollectionSerializer if record.respond_to?(:to_ary)

          get_serializer_for(record.class) if valid_for_serialization(record)
        end

        # Indicates whether or not the record specified can be serialized by Caprese
        #
        # @note The only requirement right now is that the record model has Caprese::Record included
        #
        # @param [Object] record the record to check if is valid for serialization
        # @return [True] this method either returns true, or fails - breaking control flow
        def valid_for_serialization(record)
          if record && !record.class.included_modules.include?(Caprese::Record)
            fail 'All models managed by Caprese must include Caprese::Record'
          end

          true
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
