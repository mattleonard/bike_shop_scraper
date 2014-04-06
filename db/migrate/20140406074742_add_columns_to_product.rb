class AddColumnsToProduct < ActiveRecord::Migration
  def change
  	rename_column :products, :min_price, :regular_price
  	add_column :products, :msrp_price, :float
  	add_column :products, :sale_price, :float
  end
end
