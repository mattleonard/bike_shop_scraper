class AddMpnToProduct < ActiveRecord::Migration
  def change
    add_column :products, :mpn, :string
  end
end
