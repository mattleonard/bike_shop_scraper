class AddGoogleProductCategoryToCategory < ActiveRecord::Migration
  def change
    add_column :categories, :google_product_category, :string
  end
end
