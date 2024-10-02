# frozen_string_literal: true

# We use these fields a lot to find open order cycles.
# Adding indexes seems obvious but I couldn't observe any performance gain.
# I also couldn't observe any harm. So adding these indexes will avoid any
# further investigation in the future. It's done.
class AddIndexOnOrderCyclesOrdersOpenAtAndOrdersCloseAt < ActiveRecord::Migration[7.0]
  def change
    add_index :order_cycles, :orders_open_at
    add_index :order_cycles, :orders_close_at
  end
end
