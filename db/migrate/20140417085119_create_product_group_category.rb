class CreateProductGroupCategory < ActiveRecord::Migration
  def change
  	remove_column :product_groups, :category_id, :integer
  	add_column :categories, :parent_id, :integer

    create_table :product_group_categories do |t|
      t.integer :category_id
      t.integer :product_group_id

      t.timestamps
    end
  end
end
