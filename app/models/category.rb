class Category < ActiveRecord::Base
	 has_many :product_groups, dependent: :destroy

	 scope :alphabetical, -> { order(:name) }
end
