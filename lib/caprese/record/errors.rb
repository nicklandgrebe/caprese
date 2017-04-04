require 'active_model'

module Caprese
  module Record
    class Errors < ActiveModel::Errors
      # Adds an error object for a field, with a code, to the messages hash
      #
      # @param [Symbol] attribute the attribute of the model that this error applies to
      # @param [Symbol] code the error code for the attribute
      # @option [Exception,Boolean] strict raise an exception when creating an error
      #  if Exception, raises that exception
      #  if Boolean `true`, raises ActiveModel::StrictValidationFailed
      # @option [Hash] t interpolation variables to add into the translated full message
      def add(attribute, code = :invalid, options = {})
        options = options.dup
        options[:t] ||= {}
        options[:t][:count] = options[:count]
        options[:t][:value] ||= options[:value] ||
          if attribute != :base && @base.respond_to?(attribute)
            @base.send(:read_attribute_for_validation, attribute)
          else
            nil
          end

        e = Error.new(
          model: @base.class.name.underscore.downcase,
          field: attribute == :base ? nil : @base.caprese_aliased_field(attribute),
          code: code,
          t: options[:t]
        )

        if (exception = options[:strict])
          exception = ActiveModel::StrictValidationFailed if exception == true
          raise exception, e.full_message
        end

        self[attribute] << e
      end

      # @return [Boolean] true if the model has no errors
      def empty?
        all? { |k,v| !v }
      end

      # Returns the full error messages for each error in the model
      # @note Overriden because original renders full_messages using internal helpers of self instead of error
      # @return [Hash] a hash mapped by attribute, with each value being an array of full messages for that attribute of the model
      def full_messages
        map { |_, e| e.full_message }
      end

      # @param attribute [Symbol] an attribute in the model
      # @note Overriden because original renders full_messages using internal helpers of self instead of error
      # @return [Array] an array of full error messages for a given attribute of the model
      def full_messages_for(attribute)
        (get(attribute) || []).map { |e| e.full_message }
      end

      # @note Overriden because traditionally to_a is an alias for `full_messages`, because in Rails standard there is
      #   no difference between an error and a full message, an error is that full message. With our API, an error is a
      #   model that can render full messages, but it is still a distinct model. `to_a` thus has a different meaning here
      #   than in Rails standard.
      # @return [Array] an array of all errors in the model
      def to_a
        values.flatten
      end

      # We have not and will not ever implement an XML rendering of these errors
      def to_xml(options = {})
        raise NotImplementedError
      end

      def as_json
        Hash[
          map do |field, errors|
            [field, Array.wrap(errors).map { |e| e.as_json }]
          end
        ]
      end
    end
  end
end
