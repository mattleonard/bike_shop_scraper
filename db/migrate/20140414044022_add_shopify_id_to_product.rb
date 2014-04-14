class AddShopifyIdToProduct < ActiveRecord::Migration
  def change
  	add_column :products, :shopify_id, :integer
  end
end
