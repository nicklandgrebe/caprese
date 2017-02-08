module API
  module V1
    class PostsController < ApplicationController
      private

      def permitted_create_params
        [:title, :user, :comments]
      end

      def permitted_update_params
        [:title, :user, :comments]
      end
    end
  end
end
