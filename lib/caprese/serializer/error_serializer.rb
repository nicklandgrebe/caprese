require 'caprese/serializer'

module Caprese
  class Serializer
    class ErrorSerializer < ActiveModel::Serializer::ErrorSerializer
      def resource_errors?
        object.try(:record).present?
      end

      def document_errors?
        object.try(:document).present?
      end

      # Applies aliases to fields of RecordInvalid record's errors if aliases have been applied
      # @see controller/concerns/aliasing#engaged_field_aliases
      # Otherwise returns normal error fields as_json hash
      def as_json
        json = object.as_json

        record = object.try(:record)
        aliases = object.try(:aliases)

        if record.present? && aliases.try(:any?)
          aliased_json = {}

          json.each do |k, v|
            # Iterate over engaged_field_aliases object and see if each segment of the name split by '.' is in it (meaning
            # that segment should be aliased for the error output since that is what the user is expecting)
            klass_iterator = record.class
            alias_iterator = aliases

            field_iteratee = k.to_s.split('.')
            new_error_field_name =
              field_iteratee.map do |field|
                field_alias = klass_iterator.caprese_alias_field(field)

                if i = alias_iterator.try(:[], field_alias)
                  alias_iterator = i

                  # If != true, will be an object (relationship) to traverse, find the relationship klass so we can use its aliases
                  # for the next segment of alias_iterator
                  if alias_iterator != true && (ref = klass_iterator.reflect_on_association(field)).present?
                    klass_iterator = ref.klass
                  end

                  field_alias
                elsif i = alias_iterator.try(:[], field)
                  alias_iterator = i

                  # If != true, will be an object (relationship) to traverse, find the relationship klass so we can use its aliases
                  # for the next segment of alias_iterator
                  if alias_iterator != true && (ref = klass_iterator.reflect_on_association(field)).present?
                    klass_iterator = ref.klass
                  end

                  field
                else
                  alias_iterator = {}

                  field
                end
              end

            aliased_json[new_error_field_name.join('.')] = v
          end

          aliased_json
        else
          json
        end
      end
    end
  end
end
