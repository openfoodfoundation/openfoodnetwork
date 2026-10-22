# frozen_string_literal: true

# OAuth2 provider tables for Doorkeeper, letting external applications
# authenticate OFN users.
class CreateDoorkeeperTables < ActiveRecord::Migration[7.1]
  def change
    create_applications
    create_access_grants
    create_access_tokens
  end

  private

  def create_applications
    create_table :oauth_applications do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.string :secret, null: false
      t.text :redirect_uri, null: false
      t.string :scopes, null: false, default: ''
      t.boolean :confidential, null: false, default: true
      t.timestamps null: false
    end

    add_index :oauth_applications, :uid, unique: true
  end

  def create_access_grants
    create_table :oauth_access_grants do |t|
      t.references :resource_owner, null: false, foreign_key: { to_table: :spree_users }
      t.references :application, null: false, foreign_key: { to_table: :oauth_applications }
      t.string :token, null: false, index: { unique: true }
      t.integer :expires_in, null: false
      t.text :redirect_uri, null: false
      t.string :scopes, null: false, default: ''
      t.string :code_challenge
      t.string :code_challenge_method
      t.datetime :created_at, null: false
      t.datetime :revoked_at
    end
  end

  def create_access_tokens
    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, foreign_key: { to_table: :spree_users }
      t.references :application, null: false, foreign_key: { to_table: :oauth_applications }
      t.string :token, null: false, index: { unique: true }
      t.string :refresh_token, index: { unique: true }
      t.integer :expires_in
      t.string :scopes
      t.datetime :created_at, null: false
      t.datetime :revoked_at
      t.string :previous_refresh_token, null: false, default: ""
    end
  end
end
