class CreateCommentReplies < ActiveRecord::Migration[5.1]
  def change
    create_table :comment_replies do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end
end
