class AddProductGroupIdToProduct < ActiveRecord::Migration
  def change
  	add_column :products, :product_group_id, :integer
  end
end
