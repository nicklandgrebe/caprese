class User < ApplicationRecord
  has_many :posts
  has_many :comments

  validates_presence_of :name
end
