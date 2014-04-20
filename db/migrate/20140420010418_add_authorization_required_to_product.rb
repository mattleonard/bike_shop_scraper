class AddAuthorizationRequiredToProduct < ActiveRecord::Migration
  def change
    add_column :products, :authorization_required, :boolean, default: false
  end
end
