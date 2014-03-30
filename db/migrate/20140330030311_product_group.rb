class ProductGroup < ActiveRecord::Migration
  def change
	  create_table :product_groups do |t|
	    t.string :name
	    t.string :bti_id
	    t.text :description

	    t.timestamps
	  end
  end
end
