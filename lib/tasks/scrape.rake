require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'sidekiq/api'

N = 4

namespace :scrape do
	namespace :bti do
		task :update_all => :environment do
			settings = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext'))
			heroku = Heroku::API.new(api_key: settings[:heroku_api]) 

			heroku.post_ps_scale('bti-scraper', 'work', '1')

			stats = Sidekiq::Stats.new

			Rake::Task["scrape:bti:product_groups"].invoke
			Rake::Task["scrape:bti:update_stock"].invoke

			while stats.enqueued != 0
				puts "Naping - enqueued #{stats.enqueued}"
				sleep 300
			end

			heroku.post_ps_scale('bti-scraper', 'work', '0')

			Rake::Task["shopify:product:create_new"].invoke
			Rake::Task["shopify:product:update_stock"].invoke
			Rake::Task["shopify:product:update_google_category"].invoke
			Rake::Task["shopify:product:remove_archived"].invoke
		end

		task :product_groups => :environment do
			stats = Sidekiq::Stats.new

			puts "-------------------- Getting Product Groups -------------------------"

			pages_to_scrape = (1..1300).to_a
			
			while !pages_to_scrape.empty?
				Job.submit(BTI, :scrape_product_groups, pages_to_scrape.pop(1))
			end

			while stats.enqueued > 0
				sleep 60 
			end

			remove_duplicates(ProductGroup.all)
		end

		task :update_stock, [:type] => :environment do |task, args|
			stats = Sidekiq::Stats.new
			puts "------------------------ Updating Products ------------------------"

			items = load_products(args.type)

			items.find_each do |product|
				Job.submit(BTI, :update_product, product.id)
			end

			while stats.enqueued > 0
				sleep 60 
			end

			remove_duplicates(Product.all)
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

	def remove_duplicates(items)
		seen = []
		#sort by created date and iterate
		items.find_each do |obj| 
		  if seen.map(&:bti_id).include? obj.bti_id #check if the name has been seen already
		    obj.destroy!
		  else
		    seen << obj #if not, add it to the seen array
		  end
		end
	end
end