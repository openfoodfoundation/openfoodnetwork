class AddAutomaticNotificationsToOrderCycles < ActiveRecord::Migration[6.1]
  def change
    add_column :order_cycles, :automatic_notifications, :boolean, default: false
  end
end
