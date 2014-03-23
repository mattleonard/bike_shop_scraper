class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :api_key

  def self.sanitize_action(action_name)
    unless %w(generate_api_key).include?(action_name)
      raise UserController::ActionNotFound.new(action_name)
    end
    true
  end

  def generate_api_key
  	self.api_key.destroy if self.api_key
  	self.api_key = ApiKey.create!
  	self.save
  end
end
