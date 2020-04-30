class AddTimestampsToOrderCycleSchedules < ActiveRecord::Migration
  def change
    change_table :order_cycle_schedules do |t|
      t.timestamps
    end
  end
end
