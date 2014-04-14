class ProductGroup < ActiveRecord::Base
	 validates :bti_id, presence: true
	 validates :bti_id, uniqueness: true

	 belongs_to :category

	 has_many :products, dependent: :destroy

	 scope :alphabetical, -> { order(:name) }

	 
	 state_machine :status, initial: :active do
	 	event :archive do
	 		transition :active => :archived
	 	end
	 end
end
