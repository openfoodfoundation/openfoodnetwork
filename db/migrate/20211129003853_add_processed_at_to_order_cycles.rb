class AddProcessedAtToOrderCycles < ActiveRecord::Migration[6.1]
  def change
    add_column :order_cycles, :processed_at, :datetime
  end
end
