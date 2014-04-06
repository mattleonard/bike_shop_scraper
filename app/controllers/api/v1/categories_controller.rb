module Api
	module V1
		class CategoriesController < ApplicationController
			before_filter :restrict_access
			respond_to :json

			# How to call:
			# curl http://localhost:3000/api/v1/product_groups -H 'Authorization: Token token=''"

			def index
				respond_with Category.all
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