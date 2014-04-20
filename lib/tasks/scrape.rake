require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'thread/pool'

N = 4

namespace :scrape do
	namespace :bti do
		task :get_product_groups => :environment do
			pool = Thread.pool(N)
	
			a = Mechanize.new

			page = login(a)

			puts "------------------------ Getting Product Groups -------------------------"

			(1..1300).to_a.each do |page_num|
				pool.process {
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
				}
			end
			pool.shutdown

			Rake::Task["scrape:bti:update_stock"].execute
		end

		task :update_stock, [:type] => :environment do |task, args|
			a = Mechanize.new

			page = login(a)

			puts "------------------------ Updating Products ------------------------"

			items = 
				if args.type == "new"
					Product.where('name IS NULL').active
				elsif args.type == "price"
					Product.where(regular_price: 0).active
				else
					Product.active
				end

			update_products(a, items)
		end
	end

	def update_products(a, products)
		pool = Thread.pool(N)

		products.find_each do |product|
			pool.process {
				page = a.get("https://bti-usa.com/public/item/#{product.bti_id}")

				raw_xml = page.parser

				if raw_xml.css("#errorCell").any?
					product.archive
				end

				category_parent_name = raw_xml.css('.crumbs').css('a').first(2).last.text
				category_child_name = raw_xml.css('.crumbs').css('a').first(4).last.text

				category_parent = Category.where(name: category_parent_name).first_or_create
				category_child = Category.where(name: category_child_name).first_or_create
				category_parent.children << category_child unless category_parent.children.include?(category_child)

				pg = product.product_group
				pg.categories << category_parent unless pg.categories.include?(category_parent)
				pg.categories << category_child unless pg.categories.include?(category_child)
				pg.brand = raw_xml.css('.headline').css('span').text
				pg.save

				images = raw_xml.css(".itemTable").css("img")[1]
				
				if images
					image_url = images.attributes["src"].value.gsub('thumbnails/large', 'pictures') 
					product.photo_url = "https://bti-usa.com" + image_url
				end

				product.authorization_required = !(!!page.form_with(:action => '/public/add_to_cart') or 
															!!raw_xml.search('//img/@src').to_s.match('/images/stockalert.gif'))
				product.model = pg.name.gsub(pg.brand, '')
				product.save

				parse_product_price(raw_xml, product)

			  raw_xml.css('.itemSpecTable').css('tr').each do |variation|
			  	key = variation.css('.specLabel').text
			  	value = variation.css('.specData').text
			  		
			  	unless key == "" or value == "" or 
			  				 key == "BTI part #:" or 
			  				 key == "vendor part #:" or
			  				 key == "UPC:"
			  		variation = Variation.where(key: key.gsub(':',''), value: value.gsub('/', ' / ').titleize, product_id: product.id)
			  												 .first_or_create
			  	end
			  end
			}
		end

		pool.shutdown
	end

	def parse_product_price(raw_xml, item)
		title_bar = raw_xml.css("h3")
		name = parse_noko(title_bar).gsub("\"", "")
		tds = raw_xml.css("div#bodyDiv").css("td")

		price = 0.0
		msrp = 0.0
		sale = 0.0
		stock = 0

		(0..100).to_a.each do |i|
			unless tds[i].nil?
				parsed_item = parse_noko(tds[i])
				
				case parsed_item
				when "price:"
					price = parse_noko(tds[i+1], true).to_f
				when "onsale!"
					sale = parse_noko(tds[i+1], true).to_f
				when "MSRP:"
					msrp = parse_noko(tds[i+1], true).to_f
				when "remaining:"
					stock = parse_noko(tds[i+1], true).to_i
				end
			end
		end

		item.name = name
		item.msrp_price = msrp
		item.sale_price = sale
		item.regular_price = price
		item.stock = stock
		item.save

		puts "  * #{name}\n"
		puts "  *** Price - #{price}\n"
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