class AddPhoneToSpreeUser < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_users, :phone, :string, limit: 255
  end
end
