class Comment < ApplicationRecord
  belongs_to :post, autosave: true
  belongs_to :user

  has_one :rating

  validates_presence_of :body
end
