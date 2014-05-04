
namespace :shopify do
	namespace :product do
		task :create_all => :environment do
			shopify_auth()
			create_categories()

			ProductGroup.all.each do |pg|
				if pg.products.active.pluck(:stock).any? {|s| s != 0} and
					if !pg.authorization_required?
						create_shopify_product(pg)
					end
				end
			end
		end
		task :create_new => :environment do
			shopify_auth()
			create_categories()

			ProductGroup.all.each do |pg|
				if pg.products.where(shopify_id: nil).active.pluck(:stock).any? {|s| s != 0}
					if !pg.authorization_required?
						create_shopify_product(pg)
					end
				end
			end
		end
		task :update_stock => :environment do
			shopify_auth()

			Product.where('shopify_id IS NOT NULL AND status = ?', 'active').
							complete.each do |p|
				update_stock_and_price(p.shopify_id, p)
				check_limit
			end
		end

		task :update_google_category => :environment do
			shopify_auth()

			ProductGroup.where('shopify_id IS NOT NULL AND status = ?', 'active').each do |pg|
				p pg.name
				category = pg.categories.where(parent: false).first.try(:google_product_category)
				category ||= "Sporting Goods > Outdoor Recreation > Cycling"
				update_google_meta(pg.shopify_id, category.downcase)
				check_limit
			end
		end
	end

	def shopify_auth
		p "Logging in"

		login = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext'))

		shop_url = "https://#{login['shopify_key']}:#{login['shopify_secret']}@turbosoul.myshopify.com/admin"
		ShopifyAPI::Base.site = shop_url
	end

	def create_categories
		p "Creating categories"
		Category.all.each do |c|
			check_limit

			unless ShopifyAPI::CustomCollection.where(title: c.name).any?
				collection = ShopifyAPI::CustomCollection.new
				collection.title = c.name
				
				if c.product_groups.any? and c.product_groups.first.products.any?
					image = ShopifyAPI::Image.new
					image.src = c.product_groups.first.products.first.photo_url
				end

				collection.image = image
				collection.save

				p "Creating collection #{c.name}"
			end
		end
	end

	def create_shopify_product(pg)
		p "Adding #{pg.name} -----------------------------------"

		shop_prod_id = initial_product(pg)
		check_limit()
		pg.shopify_id = shop_prod_id
		pg.save
		place_in_collections(shop_prod_id, pg)
		check_limit()
		create_options(shop_prod_id, pg)
		check_limit()

		all_images = pg.products.first.variations.where("key != 'model'")
								 .where("key != 'EAN'").where("key != 'use'")
								 .where("lower(key) LIKE ? OR lower(key) LIKE ? ", "%color%", "%lens%")
								 .any?

		if !all_images
			add_image(shop_prod_id, pg.products.first)
		end
		
		colors = []

		pg.products.complete.each_with_index do |product, index|
			check_limit()
			variant_id = add_variation(shop_prod_id, product, index)
			product_color = product.variations.where("lower(key) LIKE ? OR lower(key) LIKE ? ", "%color%", "%lens%")
							 							 .pluck(:value)
			if all_images and !colors.include?(product_color)
				add_image(shop_prod_id, product)
				colors << product_color
			end
			product.shopify_id = ShopifyAPI::Variant.last.id
			product.save
		end
	end

	def initial_product(product_group)
		p "Creating basic product"

		shop_prod = ShopifyAPI::Product.new
		shop_prod.title = product_group.name
		shop_prod.body_html = product_group.description
		shop_prod.vendor = product_group.brand
		shop_prod.tags = product_group.tags
		
		category = product_group.parent_category.name
		if !(category == "")
			shop_prod.product_type = category
		else
			shop_prod.product_type = "Miscellaneous"
		end

		shop_prod.published_scope = "global" if !product_group.products_with_stock

		shop_prod.save

		return shop_prod.id
	end

	def place_in_collections(shop_prod_id, product_group)
		product_group.categories.each do |category|
			p "Placing product in collection #{category.name}"

			shop_prod = ShopifyAPI::Product.find(shop_prod_id)
		  collect = ShopifyAPI::Collect.new
		  collect.product_id = shop_prod.id
		  if ShopifyAPI::CustomCollection.where(title: category.name).any?
			  collect.collection_id = ShopifyAPI::CustomCollection.where(title: category.name).first.id
				collect.save
			end
		end
	end

	def create_options(shop_prod_id, product_group)
		p "Creating options for products"
		shop_prod = ShopifyAPI::Product.find(shop_prod_id)
		product_group.products.first.variations.where("key != 'model'")
								 .where("key != 'EAN'").where("key != 'use'")
								 .limit(3).each_with_index do |v, index|
			if index == 0
				shop_prod.options.first.name = v.key.titleize
			else
				shop_prod.options << {"name" => v.key.titleize}
			end
		end

		variations = product_group.products.first.variations.pluck(:value)
		variation = shop_prod.variants.first
		variation.option1 = variations[0]
		variation.option2 = variations[1]
		variation.option3 = variations[2]

		variation.save

		shop_prod.save
	end

	def add_variation(shop_prod_id, product, index)
		p "Adding variation #{product.name}"

		shop_prod = ShopifyAPI::Product.find(shop_prod_id)
		
		variations = product.variations.where("key != 'model'")
									.where("key != 'EAN'").where("key != 'use'")
									.limit(3).pluck(:value)

		variant = 
		if index == 0
			shop_prod.variants.first
		else
			ShopifyAPI::Variant.new
		end

		variant.option1 = variations[0]
		variant.option2 = variations[1]
		variant.option3 = variations[2]
			
		price = product.sale_price == 0 ? product.regular_price : product.sale_price
		price = [price * 1.429 + 0.5, price + 7.5 + price * 0.029].max
		price = [price, product.msrp_price].min unless product.msrp_price == 0

		variant.sku = product.mpn
		variant.price = price
		variant.inventory_management = "shopify"
		variant.inventory_quantity = product.stock
		shop_prod.variants << variant

		shop_prod.save
	end

	def update_stock_and_price(shopify_id, product)
		p "Updating stock #{product.name}"

		variant = ShopifyAPI::Variant.find(shopify_id)

		price = product.sale_price == 0 ? product.regular_price : product.sale_price
		price = [price * 1.429 + 0.5, price + 7.5 + price * 0.029].max
		price = [price, product.msrp_price].min unless product.msrp_price == 0

		variant.sku = product.mpn
		variant.price = price
		variant.inventory_quantity = product.stock

		p variant.save
		p variant.errors.full_messages
	end

	def add_image(shop_prod_id, product)
		p "Adding image #{product.name}"

		forbidden_urls = ["https://bti-usa.com/images/stockalert.gif", 
											"https://bti-usa.com/images/Magnify.gif"]

		if !forbidden_urls.include?(product.photo_url)
			shop_prod = ShopifyAPI::Product.find(shop_prod_id)
			image = ShopifyAPI::Image.new
			image.src = product.photo_url
			shop_prod.images << image
			shop_prod.save
		end
	end

	def update_google_meta(shopify_id, category)
		p "Adding meta"

		product = ShopifyAPI::Product.find(shopify_id)

		current_meta = product.metafields.detect {|m| m.key == "google_product_type" }

		current_meta = ShopifyAPI::Metafield.new unless !!current_meta

		current_meta.key = "google_product_type"
		current_meta.namespace = "google"
		current_meta.value = category
		current_meta.owner_resource = "product"
		current_meta.owner_id = shopify_id
		current_meta.value_type = "string"

		p current_meta.save
		p current_meta.errors.full_messages
	end

	def check_limit
		if ShopifyAPI.credit_left <= 20
			p ""
			p "Credit left #{ShopifyAPI.credit_left}"
			p "Waiting for API Bucket to empty"
			p ""

			sleep 10 
		end
	end
end