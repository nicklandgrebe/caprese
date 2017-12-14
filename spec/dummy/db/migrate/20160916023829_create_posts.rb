class CreatePosts < ActiveRecord::Migration[4.2]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.timestamps
      t.references :user
    end
  end
end
