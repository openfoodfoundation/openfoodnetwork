# frozen_string_literal: true

class OrderCycleSchedule < ApplicationRecord
  belongs_to :schedule
  belongs_to :order_cycle
end
