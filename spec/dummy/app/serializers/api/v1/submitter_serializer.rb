module API
  module V1
    class SubmitterSerializer < ApplicationSerializer
      attributes :name, :created_at

      def json_key
        :submitters
      end
    end
  end
end
