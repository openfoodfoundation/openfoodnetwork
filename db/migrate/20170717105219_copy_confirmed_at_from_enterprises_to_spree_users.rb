class CopyConfirmedAtFromEnterprisesToSpreeUsers < ActiveRecord::Migration
  def up
    execute "UPDATE spree_users SET confirmed_at = enterprises.confirmed_at FROM enterprises WHERE spree_users.email = enterprises.email AND enterprises.confirmed_at IS NOT NULL"
  end
end
