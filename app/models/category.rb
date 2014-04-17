class Category < ActiveRecord::Base
	 
	belongs_to :parent, class_name: 'Category', foreign_key: 'parent_id'
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'
	has_many :product_group_categories
	has_many :product_groups, through: :product_group_categories

	scope :alphabetical, -> { order(:name) }
end
