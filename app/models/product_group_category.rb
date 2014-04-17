class ProductGroupCategory < ActiveRecord::Base

	 belongs_to :product_group
	 belongs_to :category

end
