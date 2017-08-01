module API
  module V1
    class SpecificCommentSerializer < ApplicationSerializer
      attributes :body, :created_at, :updated_at, :custom_attribute

      def custom_attribute
        0
      end
    end
  end
end
