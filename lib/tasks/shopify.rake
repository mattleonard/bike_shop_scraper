
namespace :shopify do
	namespace :product do
		task :create_all => :environment do
			shopify_auth()
			create_categories()

			ProductGroup.all.each do |pg|
				if pg.products.pluck(:stock).any? {|s| s != 0}
					sleep 0.5
					create_shopify_product(pg)
				end
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
		Category.all.each do |c|
			sleep 0.5

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
		p "Adding #{pg.name}"

		# Creating inital product
		shop_prod = ShopifyAPI::Product.new
		shop_prod.title = pg.name
		shop_prod.body_html = pg.description
		shop_prod.vendor = pg.brand
		category = Category.find(pg.category_id).name
		shop_prod.product_type = category
		shop_prod.published_scope = "global"

		shop_prod.save

		# Connects collections
	  collect = ShopifyAPI::Collect.new
	  collect.product_id = shop_prod.id
	  collect.collection_id = ShopifyAPI::CustomCollection.where(title: category).first.id
	 	collect.save

		products = pg.products

		# Creates variations for products
		products.first.variations.where("key != 'model'").each_with_index do |v, index|
			if index == 0
				shop_prod.options.first.name = v.key.titleize
			else
				shop_prod.options << {"name" => v.key.titleize}
			end
		end

		# Added variation details
		products.each_with_index do |prod, index|
			variations = prod.variations.where("key != 'model'")

			variant = 
			if index == 0
				shop_prod.variants.first
			else
				variant = ShopifyAPI::Variant.new
			end
			variant.option1 = variations[0].try(:value)
			variant.option2 = variations[1].try(:value)
			variant.option3 = variations[1].try(:value)
				
			price = prod.sale_price == 0 ? prod.regular_price : prod.sale_price
			price = [price * 1.429 + 0.5, price + 7.5 + price * 0.029].max
			price = [price, prod.msrp_price].min unless prod.msrp_price == 0

			variant.price = price
			variant.inventory_quantity = prod.stock
			shop_prod.variants << variant

			image = ShopifyAPI::Image.new
			image.src = prod.photo_url
			shop_prod.images << image

			p "-- Variation: #{prod.name}"
			p "---- price: #{price}"
			p ""

		end

	 	shop_prod.save

	 	variants = shop_prod.variants

	 	# Sets shopify id for variations
	 	variants.each_with_index do |v, i|
	 		product = products[i]
	 		product.shopify_id = v.id
	 		product.save
	 	end
	end
end