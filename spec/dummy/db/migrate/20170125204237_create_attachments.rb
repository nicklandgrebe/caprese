class CreateAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :attachments do |t|
      t.string :type
      t.string :name
      t.references :post
      t.timestamps
    end
  end
end
