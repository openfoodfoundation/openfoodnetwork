# frozen_string_literal: true

class OrderCycleSchedule < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :order_cycle
end
