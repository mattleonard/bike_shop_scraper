class AddBtiCredToUser < ActiveRecord::Migration
  def change
  	add_column :users, :bti_customer_number, :string
  	add_column :users, :bti_uname, :string
  	add_column :users, :bti_pass, :string
  end
end
