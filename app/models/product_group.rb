class ProductGroup < ActiveRecord::Base
	 validates :bti_id, presence: true
	 validates :bti_id, uniqueness: true

	 has_many :products, dependent: :destroy

	 scope :alphabetical, -> { order(:name) }
end
