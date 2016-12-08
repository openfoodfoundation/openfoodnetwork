class AddStandingOrdersConfirmedAtToOrderCycles < ActiveRecord::Migration
  def change
    add_column :order_cycles, :standing_orders_confirmed_at, :datetime
  end
end
