module API
  module V1
    class UsersController < ApplicationController
      private

      def permitted_create_params
        [:name]
      end

      def permitted_update_params
        [:name]
      end
    end
  end
end
