class AddMakeAndModelToProductGroup < ActiveRecord::Migration
  def change
  	add_column :product_groups, :brand, :string
  	add_column :products, :model, :string
  end
end
