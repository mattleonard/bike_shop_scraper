require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'thread/pool'
N = 16

namespace :scrape do
	namespace :bti do
		task :get_product_groups => :environment do

			a = Mechanize.new

			page = login(a)

			puts "------------------------ Getting Product Groups -------------------------"

			page = a.get("https://bti-usa.com/public/quicksearch/+/?page=1")

			raw_xml = page.parser

			groupIds = raw_xml.css('.groupRow')

			groupIds.each do |item|
				bti_id = item.attributes.first.last.value.gsub('groupRow__num_','').gsub('groupRow_','')
				ProductGroup.where(bti_id: bti_id).first_or_create
			end
		end

		task :get_products => :environment do

			a = Mechanize.new

			page = login(a)

			ProductGroup.all.each do |pg|

					puts "Updating #{pg.bti_id}"

					page = a.get("https://bti-usa.com/public/quicksearch/#{pg.bti_id}")

					raw_xml = page.parser

					pg.name = raw_xml.css('.groupTitleOpen').text

					pg.description = ""

					raw_xml.css('.groupBullets').css('li').each do |li|
				    pg.description += li.text + '. '
				  end

				  raw_xml.css('.itemNo').each do |itemNo|
				  	bti_id = itemNo.css('a').text.gsub('-','')
						product = Product.where(bti_id: bti_id).first_or_create
						pg.products << product

						page = a.get("https://bti-usa.com/public/item/#{product.bti_id}")

						parse_product_price(page, product)

						raw_xml = page.parser

					  raw_xml.css('.itemSpecTable').css('tr').each do |variation|
					  	key = variation.css('.specLabel').text
					  	value = variation.css('.specData').text
					  		
					  	unless key == "" or value == "" or 
					  				 key == "BTI part #:" or 
					  				 key == "vendor part #:" or
					  				 key == "UPC:"
					  		variation = Variation.where(key: key.gsub(':',''), value: value, product_id: product.id)
					  												 .first_or_create
					  		product.variations << variation
					  	end
					  end
				  end
				  pg.save
			end
		end

		task :update_stock, [:type] => :environment do |task, args|
			pool = Thread.pool(N)

			a = Mechanize.new

			page = login(a)

			puts "------------------------ Updating Products ------------------------"
			
			items = 
				if args.type == "new"
					Product.where('name IS NULL')
				else
					Product.all
				end

			p items.count
			items.alphabetical.each do |item|
				pool.process {
					page = a.get("https://bti-usa.com/public/item/#{bti_item.bti_id}")
					
					parse_product_price(page, item)
				}
			end
			pool.shutdown
		end
	end

	def parse_product_price(page, item)
		raw_xml = page.parser
		title_bar = raw_xml.css("h3")
		name = parse_noko(title_bar).gsub("\"", "")
		tds = raw_xml.css("div#bodyDiv").css("td")

		prices = []
		stock = 0

		(0..100).to_a.each do |i|
			unless tds[i].nil?
				parsed_item = parse_noko(tds[i])
				
				case parsed_item
				when "price:"
					prices << parse_noko(tds[i+1], true).to_f
				when "onsale!"
					prices << parse_noko(tds[i+1], true).to_f
				when "MSRP:"
					prices << parse_noko(tds[i+1], true).to_f
				when "remaining:"
					stock = parse_noko(tds[i+1], true).to_i
				end
			end
		end

		item.name = name
		item.min_price = prices.min
		item.stock = stock
		item.save

		puts "  * #{name}\n"
		puts "  *** Price - #{prices.min}\n"
		puts "  *** Stock - #{stock}\n"
		puts "\n"
	end

	def parse_noko(raw, with_spaces = false)
		raw_text = raw.text
		if with_spaces
			raw_text = raw_text.gsub(" ", "")
		end
		raw_text.gsub("\r", "").gsub("\n","").gsub("\t","").gsub("$","").gsub(",","")
	end

	def login(mech)
		puts "------------------------ Logging In -------------------------------"

		login = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext'))

		page = mech.get('https://bti-usa.com/public/login')

		page = page.link_with(:text => "login").click
		
		login_form = page.form_with(:action => '/public/login')
		login_form['user[customer_id]'] = login[:cust_id]
		login_form['user[user_name]'] = login[:u_name]
		login_form['user[password]'] = login[:pass]
		page = mech.submit(login_form)
		page
	end
end