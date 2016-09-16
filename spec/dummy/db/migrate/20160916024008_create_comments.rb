class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :body, null: false
      t.timestamps
      t.references :post
      t.references :user
    end
  end
end
