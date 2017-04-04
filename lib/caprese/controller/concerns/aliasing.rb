require 'active_support/concern'
require 'caprese/errors'

module Caprese
  module Aliasing
    extend ActiveSupport::Concern

    # Specifies specific resource models that have types that are aliased.
    # @note The `caprese_type` class variable of the model should also be set to the new type
    # @example
    #   {
    #     questions: attributes
    #   }
    def resource_type_aliases
      {}
    end

    # Checks resource_type_aliases for a type alias, or returns the type already stated
    #
    # @param [Symbol] type the type to search for an alias for
    # @return [Symbol] the actual type for the type alias
    def actual_type(type)
      resource_type_aliases[type] || type
    end

    # Gets the actual field name for the controller_record_class for any given field requested
    #
    # @param [Symbol,String] field the field that was requested
    # @param [Class] klass the klass to get field aliases for
    # @return [Symbol] the actual field name for the field requested
    def actual_field(field, klass = controller_record_class)
      klass.caprese_unalias_field[field = field.to_sym]
    end

    # Takes in a set of possibly aliased includes and converts them to their actual names
    #
    # @param [String] the CSV string of possibly aliased includes
    # @return [Array<String>] the actual includes
    def actual_includes(includes)
      includes.split(',').map do |i|
        if(i = i.split('.')).size > 1
          klass = nil
          i.map do |i2|
            actual = actual_field(i2, klass)
            klass = klass.reflections[actual].klass
            actual
          end.join('.')
        else
          actual_field(i)
        end
      end
    end

    # Takes in a set of possibly aliased fields with types and converts them to their actual
    # types and fields
    #
    # @param [Hash<Array>] the hash of possibly aliased resource types with their possibly aliased field specifier arrays
    # @return [Hash<Array>] the actual resource type and fields
    def actual_fields(fields)
      Hash[*fields.each do |type, fields|
        [actual_type(type), fields.map { |f| actual_field(f, record_class(type)) }]
      end]
    end
  end
end
