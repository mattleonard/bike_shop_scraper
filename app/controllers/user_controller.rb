class UserController < ApplicationController
	before_filter :authenticate_user!
	before_filter :prepare_user

	def show 
		@user = current_user
	end

	def regen_key
		@user = current_user
    @user.generate_api_key
    redirect_to action: 'show'
  end

  def prepare_user
		@user = current_user
	end
end
