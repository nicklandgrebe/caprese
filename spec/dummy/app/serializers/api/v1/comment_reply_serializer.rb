module API
  module V1
    class CommentReplySerializer < ApplicationSerializer
      belongs_to :parent, serializer: CommentSerializer
      belongs_to :child, serializer: CommentSerializer
    end
  end
end
