class Schedule < ActiveRecord::Base
  has_and_belongs_to_many :order_cycles, join_table: 'order_cycle_schedules'

  attr_sccessible :name, :order_cycle_ids
end
