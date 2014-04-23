class Product < ActiveRecord::Base
	 validates :bti_id, presence: true
	 validates :bti_id, uniqueness: true

	 belongs_to :product_group

	 has_many :variations, dependent: :destroy

	 scope :alphabetical, -> { order(:name) }
	 scope :active, -> { where(status: "active") }
	 scope :on_shopify_or_needed, -> { where('shopify_id IS NOT NULL OR status = ?', 'active') }
	 scope :need_to_scrape, -> { 
	 	where("status = 'active' OR status = 'scraped'") 
	 }
	 scope :complete, -> { 
	 	where('regular_price IS NOT NULL').
	 	where('photo_url IS NOT NULL') 
	 }
	 scope :authorization_not_required, -> {
	 	where(authorization_required: false)
	 }

	 state_machine :status, initial: :scraped do
	 	event :activate do
	 		transition any => :active
	 	end
	 	event :archive do
	 		transition any => :archived
	 	end
	 end
end
