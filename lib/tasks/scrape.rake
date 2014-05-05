require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'thread/pool'

N = 4

namespace :scrape do
	namespace :bti do
		task :update_all => :environment do
			Rake::Task["scrape:bti:product_groups"].invoke
			Rake::Task["scrape:bti:update_stock"].invoke
		end

		task :product_groups => :environment do

			puts "-------------------- Getting Product Groups -------------------------"

			pages_to_scrape = (1..1300).to_a
			
			while !pages_to_scrape.empty?
				Job.submit(BTI, :scrape_product_groups, pages_to_scrape.pop(1))
			end
		end

		task :update_stock, [:type] => :environment do |task, args|
			puts "------------------------ Updating Products ------------------------"

			items = load_products(args.type)

			items.find_each do |product|
				Job.submit(BTI, :update_product, product.id)
			end
		end
	end

	def load_products(type)
		items = 
				if type == "new"
					Product.where('name IS NULL').need_to_scrape
				elsif type == "price"
					Product.where(regular_price: 0).need_to_scrape
				else
					Product.need_to_scrape
				end

		items
	end
end