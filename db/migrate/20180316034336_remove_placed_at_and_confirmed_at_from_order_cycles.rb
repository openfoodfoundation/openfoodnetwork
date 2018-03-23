class RemovePlacedAtAndConfirmedAtFromOrderCycles < ActiveRecord::Migration
  def up
    remove_column :order_cycles, :standing_orders_placed_at
    remove_column :order_cycles, :standing_orders_confirmed_at
  end

  def down
    add_column :order_cycles, :standing_orders_placed_at, :datetime
    add_column :order_cycles, :standing_orders_confirmed_at, :datetime
  end
end
