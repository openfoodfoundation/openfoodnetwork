class AddShowApiKeyGenerationViewToSpreeUser < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :show_api_key_view, :boolean, null: false, default: false
  end
end
