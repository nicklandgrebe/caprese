require 'active_support/concern'

module Caprese
  module Record
    module Aliasing
      extend ActiveSupport::Concern

      # Provides an intermediary helper method on records that defines non-column attributes for records
      # @note This exists so there is a method by which to state that a non-column attribute should
      #   have an error source pointer like `/data/attributes/[name]` instead of `/data/relationships/[name]`
      def caprese_is_attribute?(attribute_name)
        false
      end

      # Checks that any field provided is either an attribute on the record, or an aliased field, or none
      #
      # @param [String,Symbol] field the field to check for on this record
      # @return [Boolean] whether or not the field is on the record
      def caprese_is_field?(field)
        respond_to?(field = field.to_sym) || caprese_is_attribute?(field) || caprese_field_aliases[field]
      end

      module ClassMethods
        # Provides the ability to display an aliased field name to the consumer of the API, and then map that name
        # to its real name on the server
        # @example
        #   {
        #     alias: :actual
        #   }
        def caprese_field_aliases
          {}
        end

        # The type that is serialized and responded with for this class
        def caprese_type
          self.class.name.underscore
        end
      end
    end
  end
end
