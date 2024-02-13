# frozen_string_literal: true

class CopyOidcDataToOidcAccounts < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      INSERT INTO oidc_accounts (user_id, provider, uid, created_at, updated_at)
      SELECT id, provider, uid, updated_at, updated_at
      FROM spree_users WHERE provider IS NOT NULL
    SQL
  end

  def down
    execute "DELETE FROM oidc_accounts"
  end
end
