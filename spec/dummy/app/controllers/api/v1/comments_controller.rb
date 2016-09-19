module API
  module V1
    class CommentsController < ApplicationController
      private

      def create_params
        [:body, :user, :post]
      end

      def update_params
        [:body, :user, :post]
      end
    end
  end
end
