require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'thread/pool'
N = 16

namespace :scrape do
	namespace :bti do
		task :update_catalog => :environment do
			pool = Thread.pool(N)

			a = Mechanize.new

			page = login(a)

			puts "------------------------ Updating Catalog -------------------------"

			(1..1300).to_a.each do |page_num|
				pool.process {
					puts "Processing Page #{page_num}"
					page = a.get("https://bti-usa.com/public/quicksearch/+/?page=#{page_num}")

					raw_xml = page.parser

					itemIDs = raw_xml.css('.itemLink')

					itemIDs.each do |item|
						bti_id = item.text.gsub('-','')
						BtiItem.where(bti_id: bti_id).first_or_create
					end
				}
			end

			pool.shutdown
		end

		task :update_stock => :environment do
			pool = Thread.pool(N)

			a = Mechanize.new

			page = login(a)

			puts "------------------------ Updating Products ------------------------"
			p BtiItem.count
			BtiItem.alphabetical.each do |bti_item|
				pool.process {
					page = a.get("https://bti-usa.com/public/item/#{bti_item.bti_id}")
					
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

					bti_item.name = name
					bti_item.min_price = prices.min
					bti_item.stock = stock
					bti_item.save

					puts "  * #{name}\n"
					puts "  *** Price - #{prices.min}\n"
					puts "  *** Stock - #{stock}\n"
					puts "\n"
				}
			end
			pool.shutdown
		end
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