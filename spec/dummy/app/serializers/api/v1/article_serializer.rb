module API
  module V1
    class ArticleSerializer < ApplicationSerializer
      attributes :title, :created_at, :updated_at
    end
  end
end
