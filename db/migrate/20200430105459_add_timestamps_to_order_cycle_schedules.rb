class AddTimestampsToOrderCycleSchedules < ActiveRecord::Migration[4.2]
  def change
    change_table :order_cycle_schedules do |t|
      t.timestamps
    end
  end
end
