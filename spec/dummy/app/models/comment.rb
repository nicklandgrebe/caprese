class Comment < ApplicationRecord
  belongs_to :post, autosave: true
  belongs_to :user

  has_one :rating
  has_one :comment_reply,
    foreign_key: :parent_id,
    inverse_of: :parent

  has_one :child, through: :comment_reply

  has_one :parent_reply,
    class_name: 'CommentReply',
    foreign_key: :child_id,
    inverse_of: :child

  has_one :parent_comment,
    through: :parent_reply,
    source: :parent

  validates_presence_of :body, :post

  validates_associated :rating

  before_save :body_ok

  def body_ok
    if body == 'trigger_callback'
      errors.add(:body)
      throw :abort
    end
  end
end
