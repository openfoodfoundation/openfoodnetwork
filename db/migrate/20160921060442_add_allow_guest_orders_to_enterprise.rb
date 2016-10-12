class AddAllowGuestOrdersToEnterprise < ActiveRecord::Migration
  def change
    add_column :enterprises, :allow_guest_orders, :boolean, default: true, null: false
  end
end
