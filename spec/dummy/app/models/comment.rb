class Comment < ApplicationRecord
  belongs_to :post, autosave: true
  belongs_to :user

  has_one :rating

  validates_presence_of :body

  validates_associated :rating

  before_save :body_ok

  def body_ok
    if body == 'trigger_callback'
      errors.add(:body)
      false
    end
  end
end
