module API
  module V1
    class RatingSerializer < ApplicationSerializer
      attributes :value

      belongs_to :comment
    end
  end
end
