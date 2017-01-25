class Attachment < ApplicationRecord
  belongs_to :post

  validates_presence_of :name
end
