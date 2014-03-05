require 'mechanize'

namespace :scrape do
	task :bti do
		login = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext'))

		a = Mechanize.new

		page = a.get('https://bti-usa.com/public/login')

		page = page.link_with(:text => "login").click
		
		login_form = page.form_with(:action => '/public/login')
		login_form['user[customer_id]'] = login[:cust_id]
		login_form['user[user_name]'] = login[:u_name]
		login_form['user[password]'] = login[:pass]
		page = a.submit(login_form)

		['8A501524', 'RS9618'].each do |bti_code|
			page = a.get("https://bti-usa.com/public/item/#{bti_code}")
			
			item_text = page.search(".itemTable").text

			p item_text

			prices = item_text.gsub(',', '').scan(/\$\d*.../)
			p prices.take(2)
		end
	end
end