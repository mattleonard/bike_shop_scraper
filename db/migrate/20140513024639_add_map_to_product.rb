class AddMapToProduct < ActiveRecord::Migration
  def change
    add_column :products, :map_price, :float
  end
end
