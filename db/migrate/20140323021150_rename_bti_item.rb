class RenameBtiItem < ActiveRecord::Migration
  def change
  	rename_table :bti_items, :products
  end
end
