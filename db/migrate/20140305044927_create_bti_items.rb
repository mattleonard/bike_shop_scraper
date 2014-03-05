class CreateBtiItems < ActiveRecord::Migration
  def change
    create_table :bti_items do |t|
      t.string :name
      t.string :bti_id

      t.timestamps
    end
  end
end
