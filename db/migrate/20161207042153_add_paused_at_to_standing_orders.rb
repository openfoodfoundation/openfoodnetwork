class AddPausedAtToStandingOrders < ActiveRecord::Migration
  def change
    add_column :standing_orders, :paused_at, :datetime
  end
end
