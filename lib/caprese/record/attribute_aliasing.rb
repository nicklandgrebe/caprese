module Caprese
  module Record
    module AttributeAliasing
      # Provides an intermediary helper method on records that defines non-column attributes for records
      # @note This exists so there is a method by which to state that a non-column attribute should
      #   have an error source pointer like `/data/attributes/[name]` instead of `/data/relationships/[name]`
      def caprese_is_attribute?(attribute_name)
        false
      end
    end
  end
end
