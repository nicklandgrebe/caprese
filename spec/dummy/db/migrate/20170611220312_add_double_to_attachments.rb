class AddDoubleToAttachments < ActiveRecord::Migration
  def change
    add_column :attachments, :score, :decimal
  end
end
