module API
  module V1
    class CommentSerializer < ApplicationSerializer
      attributes :body

      belongs_to :post
      belongs_to :user

      has_one :rating
    end
  end
end
