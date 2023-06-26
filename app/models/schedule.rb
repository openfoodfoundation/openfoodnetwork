# frozen_string_literal: true

class Schedule < ApplicationRecord
  has_paper_trail meta: { custom_data: proc { |schedule| schedule.order_cycle_ids.to_s } }

  has_many :order_cycle_schedules, dependent: :destroy
  has_many :order_cycles, through: :order_cycle_schedules
  has_many :coordinators, -> { distinct }, through: :order_cycles

  scope :with_coordinator, lambda { |enterprise|
                             joins(:order_cycles).where('coordinator_id = ?', enterprise.id)
                               .select('DISTINCT schedules.*')
                           }

  def current_or_next_order_cycle
    order_cycles.where('orders_close_at > (?)', Time.zone.now).order('orders_close_at ASC').first
  end
end
