module Caprese
  module Adapter
    class JsonApi
      class ResourceIdentifier
        def self.type_for(class_name, serializer_type = nil, transform_options = {})
          inflection =
            if ActiveModelSerializers.config.jsonapi_resource_type == :singular
              :singularize
            else
              :pluralize
            end

          raw_type = serializer_type || class_name.underscore
          raw_type = ActiveSupport::Inflector.public_send(inflection, raw_type)

          JsonApi.send(:transform_key_casing!, raw_type, transform_options)
        end

        # {http://jsonapi.org/format/#document-resource-identifier-objects Resource Identifier Objects}
        def initialize(serializer, options)
          @id   = id_for(serializer)
          @type = type_for(serializer, options)
        end

        def as_json
          { id: id, type: type }
        end

        protected

        attr_reader :id, :type

        private

        def type_for(serializer, transform_options)
          self.class.type_for(serializer.object.class.name, serializer.json_key, transform_options)
        end

        def id_for(serializer)
          serializer.read_attribute_for_serialization(Caprese.config.resource_primary_key).to_s
        end
      end
    end
  end
end
