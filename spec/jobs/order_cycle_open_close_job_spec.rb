require 'spec_helper'

describe OrderCycleOpenCloseJob do

  describe "finding recently opened order cycles" do
    let!(:job) { OrderCycleOpenCloseJob.new }
    let!(:order_cycle1) { create(:simple_order_cycle, orders_open_at: 11.minutes.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, orders_open_at: 9.minutes.ago) }
    let!(:order_cycle3) { create(:simple_order_cycle, orders_open_at: 2.minutes.ago, standing_orders_placed_at: 1.minute.ago ) }
    let!(:order_cycle4) { create(:simple_order_cycle, orders_open_at: 1.minute.from_now) }

    it "only returns uninitialized order cycles whose orders_open_at date is within the past 10 minutes" do
      order_cycles = job.send(:recently_opened_order_cycles)
      expect(order_cycles).to include order_cycle2
      expect(order_cycles).to_not include order_cycle1, order_cycle3, order_cycle4
    end
  end
end
