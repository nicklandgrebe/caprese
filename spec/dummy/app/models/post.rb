class Post < ApplicationRecord
  belongs_to :user, autosave: true

  has_many :attachments
  has_many :comments

  validates_presence_of :title, :user
end
