class AddStandingOrdersPlacedAtToOrderCycles < ActiveRecord::Migration
  def change
    add_column :order_cycles, :standing_orders_placed_at, :datetime
  end
end
