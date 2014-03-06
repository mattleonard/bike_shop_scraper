class BtiItem < ActiveRecord::Base
	 validates :bti_id, presence: true
	 validates :bti_id, uniqueness: true

	 scope :alphabetical, -> { order(:name) }
end
