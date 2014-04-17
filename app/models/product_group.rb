class ProductGroup < ActiveRecord::Base
	validates :bti_id, presence: true
	validates :bti_id, uniqueness: true

  has_many :product_group_categories
	has_many :categories, through: :product_group_categories

	has_many :products, dependent: :destroy

	scope :alphabetical, -> { order(:name) }


	state_machine :status, initial: :active do
		event :archive do
			transition :active => :archived
		end
	end
end
