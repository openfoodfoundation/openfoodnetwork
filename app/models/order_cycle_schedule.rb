# frozen_string_literal: true

class OrderCycleSchedule < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :schedule
  belongs_to :order_cycle
end
