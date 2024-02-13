# frozen_string_literal: true

class CreateOidcAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_accounts do |t|
      # We may allow multiple OIDC accounts per user in the future but for now
      # we assume only one and therefore make this unique.
      t.belongs_to :user, null: false, foreign_key: { to_table: :spree_users },
                          index: { unique: true }
      t.string :provider
      t.string :uid, null: false, index: { unique: true }
      t.string :token
      t.string :refresh_token

      t.timestamps
    end
  end
end
