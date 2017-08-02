module Caprese
  module Adapter
    class JsonApi
      # meta
      # definition:
      #   JSON Object
      #
      # description:
      #   Non-standard meta-information that can not be represented as an attribute or relationship.
      # structure:
      #   {
      #     attitude: 'adjustable'
      #   }
      class Schema
        def initialize(serializer)
          @serializer = serializer
          @object = serializer.object

          # Use the return value of the block unless it is nil.
          if serializer._meta.respond_to?(:call)
            @value = instance_eval(&serializer._meta)
          else
            @value = serializer._meta
          end
        end

        def as_json
          @value
        end

        protected

        attr_reader :object

        private

        # {http://jsonapi.org/format/#document-resource-object-attributes Document Resource Object Attributes}
        # attributes
        # definition:
        #   JSON Object
        #
        # patternProperties:
        #   ^(?!relationships$|links$)\\w[-\\w_]*$
        #
        # description:
        #   Members of the attributes object ("attributes") represent information about the resource
        #   object in which it's defined.
        #   Attributes may contain any valid JSON value
        # structure:
        #   {
        #     foo: 'bar'
        #   }
        def attributes
          @serializer.adapter
        end

        def custom_keys
          @serializer.schema? ? @serializer.custom : {}
        end
      end
    end
  end
end
