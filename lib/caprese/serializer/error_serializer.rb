require 'caprese/serializer'

module Caprese
  class Serializer
    class ErrorSerializer < ActiveModel::Serializer::ErrorSerializer
      delegate :as_json, to: :object

      def resource_errors?
        object.try(:record).present?
      end
    end
  end
end
