class RemoveDefaultFromProductGroup < ActiveRecord::Migration
  def change
  	remove_column :product_groups, :status
  	add_column :product_groups, :status, :string
  end
end
