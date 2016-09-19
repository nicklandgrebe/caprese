module API
  module V1
    class PostSerializer < ApplicationSerializer
      attributes :title, :created_at, :updated_at

      belongs_to :user

      has_many :comments
    end
  end
end
