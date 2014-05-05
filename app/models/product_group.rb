class ProductGroup < ActiveRecord::Base
	validates :bti_id, presence: true
	validates :bti_id, uniqueness: true

  has_many :product_group_categories
	has_many :categories, through: :product_group_categories

	has_many :products, dependent: :destroy

	scope :alphabetical, -> { order(:name) }


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

	def self.scrape_product_groups(pages)
		a = Mechanize.new

		page = BTI.login(a)

		pages.to_a.each do |page_num|
			puts "Scraping page #{page_num}"

			page = a.get("https://bti-usa.com/public/quicksearch/+/?page=#{page_num}")

			raw_xml = page.parser

			groupRows = raw_xml.css('.groupRow')

			groupRows.each do |item|
				bti_id = item.attributes.first.last.value
										 .gsub('groupItemsDiv__num_','')
										 .gsub('groupItemsDiv_','')
				pg = ProductGroup.where(bti_id: bti_id).first_or_create
				pg.name = item.css('.groupTitleOpen').text

				puts "Updating #{pg.name} product group"

				pg.description = ""

				item.css('.groupBullets').css('li').each do |li|
			    pg.description += li.text + '. '
			  end

			  item.css('.itemNo').each do |itemNo|
			  	bti_id = itemNo.css('a').text.gsub('-','')
					product = Product.where(bti_id: bti_id, product_group_id: pg.id).first_or_create
			  end
			  pg.save
			end
		end
	end
end
