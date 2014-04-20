class RefactorParentForCategory < ActiveRecord::Migration
  def change
  	remove_column :categories, :parent_id, :integer
  	add_column :categories, :parent, :boolean, default: false

  	remove_column :products, :status
  	add_column :products, :status, :string
  end
end
