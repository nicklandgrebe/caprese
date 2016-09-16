module API
  module V1
    class PostSerializer < ApplicationSerializer
      attributes :title

      belongs_to :user

      has_many :comments
    end
  end
end
