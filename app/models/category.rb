class Category < ActiveRecord::Base
	 has_many :product_groups

	 scope :alphabetical, -> { order(:name) }
end
