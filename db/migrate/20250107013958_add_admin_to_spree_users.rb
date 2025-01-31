# frozen_string_literal: true

# We'll replace our only role "admin" with a simple flag.
class AddAdminToSpreeUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_users, :admin, :boolean, default: false, null: false
  end
end
