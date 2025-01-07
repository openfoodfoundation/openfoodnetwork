# frozen_string_literal: true

class CopyAdminAttributeToUsers < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE spree_users SET admin = true WHERE id IN (
        SELECT user_id FROM spree_roles_users WHERE role_id IN (
          SELECT id FROM spree_roles WHERE name = 'admin'
        )
      )
    SQL
  end
end
