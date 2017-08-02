require 'caprese/serializer'

module Caprese
  class Serializer
    def schema?
      false
    end

    class SchemaSerializer < Caprese::Serializer
      def schema?
        true
      end

      delegate :collection?, :polymorphic?, to: :object

      def attributes(_)
        Hash[
          fields_for(:attributes).map do |name, attribute|
            [
              name,
              {
                type: attribute.type,
                required: attribute.required
              }
            ]
          end
        ]
      end

      def associations(_)
        Enumerator.new do |y|
          fields_for(:relationships).each do |name, relationship|
            SchemaAssociation.new(self.class.new(relationship))
          end
        end
      end

      def child_serializers
        object.children.map { |schema_object| self.class.new(schema_object) }
      end

      def custom
        fields_for(:custom)
      end

      private

      def fields_for(type)
        @fields ||= Hash[
          [:attributes, :custom, :relationships].map do |field_type|
            [
              field_type,
              object.fields[field_type]
            ] if object.fields[field_type]
          end
        ][type]
      end

      SchemaAssociation = Struct.new(:serializer)
      end
    end
  end
end
