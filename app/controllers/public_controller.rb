class PublicController < ApplicationController
	before_filter :prepare_user

	def index
		@current_tab = "home"
	end

	def documentation
		@current_tab = "documentation"
	end

	def contact
		@current_tab = "contact"
		render "contact_us/contacts/new"
	end

	def prepare_user
		@user = current_user
	end
end
