require 'active_support/concern'

module Caprese
  class Serializer < ActiveModel::Serializer
    module Relationships
      extend ActiveSupport::Concern

      # Applies further scopes to a collection association when rendered as part of included document
      # @note Can be overridden to customize scoping at a per-relationship level
      #
      # @example
      #   def relationship_scope(name, scope)
      #     case name
      #     when :transactions
      #       scope.by_merchant(...)
      #     when :orders
      #       scope.by_user(...)
      #     end
      #   end
      #
      # @param [String] name the name of the association
      # @param [Relation] scope the scope corresponding to a collection association
      def relationship_scope(name, scope)
        scope
      end
    end
  end
end
