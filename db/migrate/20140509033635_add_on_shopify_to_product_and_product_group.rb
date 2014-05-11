class AddOnShopifyToProductAndProductGroup < ActiveRecord::Migration
  def change
  	add_column :product_groups, :on_shopify, :boolean, default: false
  	add_column :products, :on_shopify, :boolean, default: false

  	ProductGroup.reset_column_information
  	Product.reset_column_information

  	ProductGroup.where(status: ["active", "archived"]).update_all(on_shopify: true)
  	Product.where(status: ["active", "archived"]).update_all(on_shopify: true)
  end
end
