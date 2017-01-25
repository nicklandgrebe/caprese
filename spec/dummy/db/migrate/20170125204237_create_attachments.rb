class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :type
      t.string :name
      t.references :post
      t.timestamps
    end
  end
end
