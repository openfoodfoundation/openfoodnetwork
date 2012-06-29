# This migration comes from spree_api (originally 20120411123334)
class ResizeApiKeyField < ActiveRecord::Migration
  def change
    change_column :spree_users, :api_key, :string, :limit => 48
  end
end
