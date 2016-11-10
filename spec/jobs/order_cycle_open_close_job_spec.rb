require 'spec_helper'

describe OrderCycleOpenCloseJob do
  let!(:job) { OrderCycleOpenCloseJob.new }

  describe "finding recently opened order cycles" do
    let!(:order_cycle1) { create(:simple_order_cycle, orders_open_at: 11.minutes.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, orders_open_at: 9.minutes.ago) }
    let!(:order_cycle3) { create(:simple_order_cycle, orders_open_at: 2.minutes.ago, standing_orders_placed_at: 1.minute.ago ) }
    let!(:order_cycle4) { create(:simple_order_cycle, orders_open_at: 1.minute.from_now) }

    it "only returns unprocessed order cycles whose orders_open_at date is within the past 10 minutes" do
      order_cycles = job.send(:recently_opened_order_cycles)
      expect(order_cycles).to include order_cycle2
      expect(order_cycles).to_not include order_cycle1, order_cycle3, order_cycle4
    end
  end

  describe "running the job" do
    let!(:order_cycle) { create(:simple_order_cycle, orders_open_at: 5.minutes.ago) }

    it "marks the order cycle as processed by setting standing_orders_placed_at" do
      expect{job.perform}.to change{order_cycle.reload.standing_orders_placed_at}
      expect(order_cycle.standing_orders_placed_at).to be_within(5.seconds).of Time.now
    end

    it "enqueues a StandingOrderPlacementJob for each recently opened order_cycle" do
      expect{job.perform}.to enqueue_job StandingOrderPlacementJob
    end
  end
end
