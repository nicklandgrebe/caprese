class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :value, null: false
      t.timestamps
      t.references :comment
    end
  end
end
