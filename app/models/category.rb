class Category < ActiveRecord::Base
	 
	has_many :product_group_categories
	has_many :product_groups, through: :product_group_categories

	scope :alphabetical, -> { order(:name) }
end
