require 'nokogiri'
require 'open-uri'

namespace :scrape do
	task :bti do
		doc = Nokogiri::HTML(open('http://www.bti-usa.com'))
		p doc
	end
end