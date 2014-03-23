class AddUserIdToApiKey < ActiveRecord::Migration
  def change
  	add_column :api_keys, :user_id, :integer
  end
end
