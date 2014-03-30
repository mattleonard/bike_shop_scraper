class Product < ActiveRecord::Base
	 validates :bti_id, presence: true
	 validates :bti_id, uniqueness: true

	 belongs_to :product_group

	 has_many :variations, dependent: :destroy

	 scope :alphabetical, -> { order(:name) }
end
