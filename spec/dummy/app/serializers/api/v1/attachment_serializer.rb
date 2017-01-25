module API
  module V1
    class AttachmentSerializer < ApplicationSerializer
      attributes :name, :created_at, :updated_at

      belongs_to :post
    end
  end
end
