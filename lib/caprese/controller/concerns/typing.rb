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
      begin
        type.to_s.classify.constantize
      rescue NameError => e
        if resource_type_aliases[type.to_sym]
          record_class(resource_type_aliases[type.to_sym].to_sym)
        else
          raise e
        end
      end
    end

    # Gets the record class for the current controller
    #
    # @return [Class] the record class for the current controller
    def controller_record_class
      record_class(unversion(params[:controller]))
    end

    # Checks if a given type mismatches the controller type
    #
    # @param [String] type the pluralized type to check ('products','orders',etc.)
    def fail_on_type_mismatch(type)
      failed = false

      begin
        failed = record_class(type) != controller_record_class
      rescue NameError
        failed = true
      end

      if failed
        invalid_typed_record = controller_record_class.new
        invalid_typed_record.errors.add(:type)

        fail RecordInvalidError.new(invalid_typed_record)
      end
    end
  end
end
