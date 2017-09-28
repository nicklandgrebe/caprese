module API
  module V1
    class UserSerializer < ApplicationSerializer
      attributes :name, :created_at, :updated_at

      has_many :comments
      has_many :posts

      link :self do
        'override'
      end
    end
  end
end
