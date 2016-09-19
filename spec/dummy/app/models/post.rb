class Post < ApplicationRecord
  belongs_to :user

  has_many :comments

  validates_presence_of :title
end
