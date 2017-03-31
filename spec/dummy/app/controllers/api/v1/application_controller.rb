module API
  module V1
    class ApplicationController < API::ApplicationController
      def static
        render 'application/static'
      end
    end
  end
end
