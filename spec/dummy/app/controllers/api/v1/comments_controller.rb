module API
  module V1
    class CommentsController < ApplicationController
      private

      def permitted_create_params
        [:body, :user, post: [:title, :user]]
      end

      def permitted_update_params
        [:body, :user, :post]
      end
    end
  end
end
