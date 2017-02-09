require 'caprese/adapter/json_api/json_pointer'

module Caprese
  module Adapter
    class JsonApi
      module Error
        # rubocop:disable Style/AsciiComments
        UnknownSourceTypeError = Class.new(ArgumentError)

        def self.param_errors(error_serializer, options)
          error_attributes = error_serializer.as_json
          [
            {
              code: error_attributes[:code],
              detail: error_attributes[:message],
              source: error_source(:parameter, nil, error_attributes[:field])
            }
          ]
        end

        # Builds a JSON API Errors Object
        # {http://jsonapi.org/format/#errors JSON API Errors}
        #
        # @param [Caprese::Serializer::ErrorSerializer] error_serializer
        # @return [Array<Symbol, Array<String>>] i.e. attribute_name, [attribute_errors]
        def self.resource_errors(error_serializer, options)
          error_serializer.as_json.flat_map do |attribute_name, attribute_errors|
            attribute_name = JsonApi.send(:transform_key_casing!, attribute_name,
              options)
            attribute_error_objects(error_serializer.object.record, attribute_name, attribute_errors)
          end
        end

        # definition:
        #   JSON Object
        #
        # properties:
        #   ☐ id      : String
        #   ☐ status  : String
        #   ☐ code    : String
        #   ☐ title   : String
        #   ☑ detail  : String
        #   ☐ links
        #   ☐ meta
        #   ☑ error_source
        #
        # description:
        #   id     : A unique identifier for this particular occurrence of the problem.
        #   status : The HTTP status code applicable to this problem, expressed as a string value
        #   code   : An application-specific error code, expressed as a string value.
        #   title  : A short, human-readable summary of the problem. It **SHOULD NOT** change from
        #     occurrence to occurrence of the problem, except for purposes of localization.
        #   detail : A human-readable explanation specific to this occurrence of the problem.
        # structure:
        #   {
        #     title: 'SystemFailure',
        #     detail: 'something went terribly wrong',
        #     status: '500'
        #   }.merge!(errorSource)
        def self.attribute_error_objects(record, attribute_name, attribute_errors)
          attribute_errors.map do |attribute_error|
            {
              source: error_source(:pointer, record, attribute_name),
              code: attribute_error[:code],
              detail: attribute_error[:message]
            }
          end
        end

        # errorSource
        # description:
        #   oneOf
        #     ☑ pointer   : String
        #     ☑ parameter : String
        #
        # description:
        #   pointer: A JSON Pointer RFC6901 to the associated entity in the request document e.g. "/data"
        #   for a primary data object, or "/data/attributes/title" for a specific attribute.
        #   https://tools.ietf.org/html/rfc6901
        #
        #   parameter: A string indicating which query parameter caused the error
        # structure:
        #   if is_attribute?
        #     {
        #       pointer: '/data/attributes/red-button'
        #     }
        #   else
        #     {
        #       parameter: 'pres'
        #     }
        #   end
        RESERVED_ATTRIBUTES = %w(type)
        def self.error_source(source_type, record, attribute_name)
          case source_type
          when :pointer
            # [type ...] and other primary data variables
            if RESERVED_ATTRIBUTES.include?(attribute_name.to_s)
              {
                pointer: JsonApi::JsonPointer.new(:primary_data, record, attribute_name)
              }
            elsif record.has_attribute?(attribute_name)
              {
                pointer: JsonApi::JsonPointer.new(:attribute, record, attribute_name)
              }
            elsif (relationship_data_items = attribute_name.to_s.split('.')).size > 1
              if RESERVED_ATTRIBUTES.include?(relationship_data_items.last)
                {
                  pointer: JsonApi::JsonPointer.new(:relationship_primary_data, record, relationship_data_items)
                }
              else
                {
                  pointer: JsonApi::JsonPointer.new(:relationship_attribute, record, attribute_name)
                }
              end
            else
              {
                pointer: JsonApi::JsonPointer.new(:relationship_base, record, attribute_name)
              }
            end
          when :parameter
            {
              parameter: attribute_name
            }
          else
            fail UnknownSourceTypeError, "Unknown source type '#{source_type}' for attribute_name '#{attribute_name}'"
          end
        end
        # rubocop:enable Style/AsciiComments
      end
    end
  end
end
