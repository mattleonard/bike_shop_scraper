class Product < ActiveRecord::Base
	 validates :bti_id, presence: true
	 validates :bti_id, uniqueness: true

	 belongs_to :product_group

	 has_many :variations, dependent: :destroy

	 scope :alphabetical, -> { order(:name) }
	 scope :active, -> { where(status: "active") }

	 state_machine :status, initial: :active do
	 	event :archive do
	 		transition :active => :archived
	 	end
	 end

end
