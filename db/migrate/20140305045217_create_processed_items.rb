class CreateProcessedItems < ActiveRecord::Migration
  def change
    create_table :processed_items do |t|
      t.string :name
      t.integer :stock

      t.timestamps
    end
  end
end
