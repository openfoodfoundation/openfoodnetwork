# frozen_string_literal: true

# Stores the OpenID Connect nonce sent with an authorization request, to put it
# in the ID token issued for that grant, and the time the user logged in, which
# ID tokens report even after a refresh.
class CreateDoorkeeperOpenidConnectTables < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_openid_requests do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :access_grant, null: false, index: true
      t.string :nonce, null: false
    end

    add_foreign_key :oauth_openid_requests, :oauth_access_grants,
                    column: :access_grant_id, on_delete: :cascade

    add_column :oauth_access_grants, :auth_time, :datetime
    add_column :oauth_access_tokens, :auth_time, :datetime
  end
end
