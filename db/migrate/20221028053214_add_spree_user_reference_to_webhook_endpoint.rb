# frozen_string_literal: true

class AddSpreeUserReferenceToWebhookEndpoint < ActiveRecord::Migration[6.1]
  def change
    add_column :webhook_endpoints, :user_id, :bigint, default: 0, null: false
    add_index :webhook_endpoints, :user_id
    add_foreign_key :webhook_endpoints, :spree_users, column: :user_id
  end
end
