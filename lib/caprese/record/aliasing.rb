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
