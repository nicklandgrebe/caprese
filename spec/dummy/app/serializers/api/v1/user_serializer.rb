module API
  module V1
    class UserSerializer < ApplicationSerializer
      attributes :name

      has_many :comments
      has_many :posts
    end
  end
end
