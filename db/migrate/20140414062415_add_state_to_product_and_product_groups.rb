class AddStateToProductAndProductGroups < ActiveRecord::Migration
  def change
  	add_column :products, :status, :string, default: "active"
  	add_column :product_groups, :status, :string, default: "active"
  end
end
