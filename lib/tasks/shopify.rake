
namespace :shopify do
	namespace :product do
		task :create_all => :environment do
			shopify_auth()
			create_categories()

			ProductGroup.all.each do |pg|
				if pg.products.active.pluck(:stock).any? {|s| s != 0}
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
		p "Creating categories"
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
		p "Adding #{pg.name} -----------------------------------"

		shop_prod_id = initial_product(pg)
		place_in_collection(shop_prod_id, pg)
		create_options(shop_prod_id, pg)
		pg.products.each_with_index do |product, index|
			variant_id = add_variation(shop_prod_id, product, index)
			add_image(shop_prod_id, product)
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
		category = Category.find(product_group.category_id).name
		shop_prod.product_type = category
		shop_prod.published_scope = "global"

		p shop_prod.save
		p shop_prod.errors.full_messages
	end

	def place_in_collection(shop_prod_id, product_group)
		p "Placing product in collection"

		category = Category.find(product_group.category_id).name
		shop_prod = ShopifyAPI::Product.last
	  collect = ShopifyAPI::Collect.new
	  collect.product_id = shop_prod.id
	  collect.collection_id = ShopifyAPI::CustomCollection.where(title: category).first.id
	 	p collect.save
	 	p collect.errors.full_messages
	end

	def create_options(shop_prod_id, product_group)
		p "Creating options for products"
		shop_prod = ShopifyAPI::Product.last
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

		p variation.save
		p variation.errors.full_messages

		p shop_prod.save
		p shop_prod.errors.full_messages
	end

	def add_variation(shop_prod_id, product, index)
		p "Adding variation #{product.name}"

		shop_prod = ShopifyAPI::Product.last
		
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

		variant.price = price
		variant.inventory_management = "shopify"
		variant.inventory_quantity = product.stock
		shop_prod.variants << variant

		p shop_prod.save
		p shop_prod.full_messages
	end

	def add_image(shop_prod_id, product)
		p "Adding image #{product.name}"

		shop_prod = ShopifyAPI::Product.last
		image = ShopifyAPI::Image.new
		image.src = product.photo_url
		shop_prod.images << image
		shop_prod.save
	end
end