class RefactorParentForCategory < ActiveRecord::Migration
  def change
  	remove_column :categories, :parent_id, :integer
  	add_column :categories, :parent, :boolean, default: false
  end
end
