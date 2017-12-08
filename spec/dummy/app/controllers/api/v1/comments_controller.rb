module API
  module V1
    class CommentsController < ApplicationController
      private

      def permitted_create_params
        [
          :body, :content, :user,
          post: [:name, :title, user: [:name]],
          article: [:name, :title, user: [:name], submitter: [:name]],
          rating: [:value]
        ]
      end

      def permitted_update_params
        [
          :body, :content, :user,
          post: [:name, :title, user: [:name]],
          article: [:name, :title, user: [:name], submitter: [:name]],
          rating: [:value]
        ]
      end
    end
  end
end
