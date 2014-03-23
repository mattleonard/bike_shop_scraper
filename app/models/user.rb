require 'mechanize'
require 'nokogiri'
require 'open-uri'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  attr_encrypted :bti_customer_number, :key => :encryption_key
  attr_encrypted :bti_uname, :key => :encryption_key
  attr_encrypted :bti_pass, :key => :encryption_key

  has_one :api_key

  def self.sanitize_action(action_name)
    unless %w(generate_api_key).include?(action_name)
      raise UserController::ActionNotFound.new(action_name)
    end
    true
  end

  def generate_api_key
    if self.authorized_for_bti?
    	self.api_key.destroy if self.api_key
    	self.api_key = ApiKey.create!
    	self.save
    else
      self.api_key = nil
    end
  end

  def authorized_for_bti
    mech = Mechanize.new

    page = mech.get('https://bti-usa.com/public/login')

    page = page.link_with(:text => "login").click
    
    login_form = page.form_with(:action => '/public/login')
    login_form['user[customer_id]'] = 
    login_form['user[user_name]'] = 
    login_form['user[password]'] = 
    page = mech.submit(login_form)

    !page.link_with(:text => "Log-Out").nil?
  end

  def encryption_key
    Sekrets.settings_for(Rails.root.join('sekrets', 'db_encrypt'))[:bti_key]
  end
end
