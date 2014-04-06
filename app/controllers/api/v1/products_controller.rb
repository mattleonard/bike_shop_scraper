module Api
	module V1
		class ProductsController < ApplicationController
			before_filter :restrict_access
			respond_to :json

			# How to call:
			# curl http://localhost:3000/api/v1/products -H 'Authorization: Token token=''"

			def index
				products = Product.offset(params[:offset]).limit(3000)
				products.each do |p|
					p.name = p.variations.map{|v| v.value}.join(', ')
				end
				respond_with products
			end

			def show
				respond_with Product.where(bti_id: params[:id].gsub('-','')).first
			end

			private
			def restrict_access
				authenticate_or_request_with_http_token do |token, options|
			    ApiKey.exists?(access_token: token)
			  end
			end
		end
	end
end