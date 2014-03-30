class Variation < ActiveRecord::Migration
  def change
  	create_table :variations do |t|
	    t.string :value
	    t.string :key
	    t.integer :product_id

	    t.timestamps
	  end
  end
end
