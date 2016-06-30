class CreateOrderCycleSchedules < ActiveRecord::Migration
  def change
    create_table :order_cycle_schedules do |t|
      t.references :order_cycle, null: false
      t.references :schedule, null: false
    end

    add_index :order_cycle_schedules, :order_cycle_id
    add_index :order_cycle_schedules, :schedule_id

    add_foreign_key :order_cycle_schedules, :order_cycles, name: 'oc_schedules_order_cycle_id_fk'
    add_foreign_key :order_cycle_schedules, :schedules, name: 'oc_schedules_schedule_id_fk'
  end
end
