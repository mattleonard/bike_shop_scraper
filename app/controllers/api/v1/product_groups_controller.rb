module Api
	module V1
		class ProductGroupsController < ApplicationController
			before_filter :restrict_access
			respond_to :json

			# How to call:
			# curl http://localhost:3000/api/v1/product_groups -H 'Authorization: Token token=''"

			def index
				respond_with ProductGroup.all
			end

			def show
				respond_with ProductGroup.where(bti_id: params[:id].gsub('-','')).first
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