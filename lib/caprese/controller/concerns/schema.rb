require 'active_support/concern'
require 'caprese/serializer/schema_serializer'

# Defines schema for use in OPTIONS requests as well as managing OPTIONS requests
module Caprese
  module Schema
    extend ActiveSupport::Concern

    def options
      if resource_schema.any?
        render(
          json: Fields.resource(controller_record_class).shape(resource_schema),
          serializer: Caprese::Serializer::SchemaSerializer
        )
      else
        head :no_content
      end
    end

    def resource_schema
      {}
    end

    class Fields
      attr_reader :children, :required

      def initialize(type)
        @type = type
      end

      def self.string
        self.class.new(:strings)
      end

      def self.decimal
        self.class.new(:decimals)
      end

      def self.integer
        self.class.new(:integers)
      end

      def self.resource(*types)
        ::Relationship.new(types, false)
      end

      def self.collection_of(*types)
        ::Relationship.new(types, true)
      end

      def is_required(predicate)
        @required = !!predicate.call
      end

      def custom(proc)
        self.class.custom(proc, self)
      end

      def self.custom(proc, mutater = self)
        proc(mutater)
      end

      def collection?
        false
      end

      def polymorphic?
        false
      end

      def children
        [self]
      end

      class Attribute < Fields

      end

      class Relationship < Fields
        def initialize(type, collection)
          @type = type
          @collection = collection
        end

        def alias_type(alias)
          @type_alias = alias
          self
        end

        def collection?
          @collection
        end

        def polymorphic?
          @type.is_a(Array)
        end

        def count(n)
          @count = n
          self
        end

        def data(record)
          @data = record
          self
        end

        def for_each(array, proc)
          @children = array.map { |i| proc.call(self.clone, i) }
          self
        end

        def shape(shape)
          @shape = shape
        end

        private

        def clone

        end
      end
    end
  end
end
