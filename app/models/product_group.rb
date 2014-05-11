class ProductGroup < ActiveRecord::Base
	validates :bti_id, presence: true
	validates :bti_id, uniqueness: true

  has_many :product_group_categories
	has_many :categories, through: :product_group_categories

	has_many :products, dependent: :destroy

	scope :alphabetical, -> { order(:name) }

	scope :live, -> { where(status: ['scraped','active']) }

	scope :need_to_remove, -> {
		where(on_shopify: true, status: "archived").
		where("shopify_id IS NOT NULL")
	}


	state_machine :status, initial: :scraped do
	 	event :activate do
	 		transition any => :active
	 	end
		event :archive do
			transition any => :archived
		end
	end

	def parent_category
		self.categories.select {|c| c.parent == true }.first
	end

	def products_with_stock
		self.products.any? {|p| p.stock != 0 }
	end

	def authorization_required?
		self.products.all? {|p| p.authorization_required == true }
	end

	def tags
		self.categories.pluck(:name).join(', ')
	end
end
