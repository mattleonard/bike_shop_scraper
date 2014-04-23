class AddShopifyIdToProductGroup < ActiveRecord::Migration
  def change
  	add_column :product_groups, :shopify_id, :integer
  end
end
