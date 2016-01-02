# This migration comes from spree_api (originally 20120530054546)
class RenameApiKeyToSpreeApiKey < ActiveRecord::Migration
  def change
    rename_column :spree_users, :api_key, :spree_api_key unless defined?(User)
  end
end
