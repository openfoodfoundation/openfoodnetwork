class AddDisabledAtToSpreeUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :disabled_at, :datetime
  end
end
