# This migration comes from spree_auth (originally 20120203010234)
class AddResetPasswordSentAtToSpreeUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :reset_password_sent_at, :datetime
  end
end
