require 'active_support/concern'
require 'caprese/errors'

# Manages type determination and checking for a given controller
module Caprese
  module Typing
    extend ActiveSupport::Concern

    # Gets the class for a record type
    # @note "record type" can be plural, singular, or classified
    #   i.e. 'orders', 'order', or 'Order'
    #
    # @example
    #   record_class(:orders) # => Order
    #
    # @param [Symbol] type the record type to get the class for
    # @return [Class] the class for a given record type
    def record_class(type)
      type.to_s.classify.constantize
    end

    # Gets the record class for the current controller
    #
    # @return [Class] the record class for the current controller
    def controller_record_class
      record_class(unversion(params[:controller]))
    end

    # Checks if a given type mismatches the controller type
    # @note Throws :invalid_type error if true
    #
    # @param [String] type the pluralized type to check ('products','orders',etc.)
    def fail_on_type_mismatch(type)
      unless record_class(type) == controller_record_class
        fail InvalidTypeError.new(type)
      end
    end
  end
end
