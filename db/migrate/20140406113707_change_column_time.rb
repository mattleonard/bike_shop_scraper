class ChangeColumnTime < ActiveRecord::Migration
  def change
  	remove_column :products, :regular_price
  	add_column :products, :regular_price, :float
  end
end
