# frozen_string_literal: true

class CreateDfcPermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :dfc_permissions do |t|
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.references :enterprise, null: false, foreign_key: true
      t.string :grantee, null: false
      t.string :scope, null: false

      t.timestamps
    end
    add_index :dfc_permissions, :grantee
    add_index :dfc_permissions, :scope
  end
end
