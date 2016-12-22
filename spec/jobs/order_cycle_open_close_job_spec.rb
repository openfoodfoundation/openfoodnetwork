require 'spec_helper'

describe OrderCycleOpenCloseJob do
  let!(:job) { OrderCycleOpenCloseJob.new }

  describe "finding recently opened order cycles" do
    let!(:order_cycle1) { create(:simple_order_cycle, orders_open_at: 11.minutes.ago, updated_at: 11.minutes.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, orders_open_at: 11.minutes.ago, updated_at: 9.minutes.ago) }
    let!(:order_cycle3) { create(:simple_order_cycle, orders_open_at: 9.minutes.ago, updated_at: 9.minutes.ago) }
    let!(:order_cycle4) { create(:simple_order_cycle, orders_open_at: 1.minute.from_now) }

    it "returns unprocessed order cycles whose orders_open_at or updated_at date is within the past 10 minutes" do
      order_cycles = job.send(:recently_opened_order_cycles)
      expect(order_cycles).to include order_cycle2, order_cycle3
      expect(order_cycles).to_not include order_cycle1, order_cycle4
    end
  end

  describe "finding recently closed order cycles" do
    let!(:order_cycle1) { create(:simple_order_cycle, orders_close_at: 11.minutes.ago, updated_at: 11.minutes.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, orders_close_at: 11.minutes.ago, updated_at: 9.minutes.ago) }
    let!(:order_cycle3) { create(:simple_order_cycle, orders_close_at: 9.minutes.ago, updated_at: 9.minutes.ago) }
    let!(:order_cycle4) { create(:simple_order_cycle, orders_close_at: 1.minute.from_now) }

    it "returns unprocessed order cycles whose orders_close_at or updated_at date is within the past 10 minutes" do
      order_cycles = job.send(:recently_closed_order_cycles)
      expect(order_cycles).to include order_cycle2, order_cycle3
      expect(order_cycles).to_not include order_cycle1, order_cycle4
    end
  end

  describe "finding placeable proxy_orders for a particular order cycle" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 10.minutes.from_now) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now) }
    let(:standing_order2) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now, paused_at: 1.minute.ago) }
    let(:standing_order3) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now, canceled_at: 1.minute.ago) }
    let(:standing_order4) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 11.minutes.from_now, ends_at: 20.minutes.from_now) }
    let(:standing_order5) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 1.minute.ago, ends_at: 9.minutes.from_now) }
    let!(:proxy_order1) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle2) } # OC Mismatch
    let!(:proxy_order2) { create(:proxy_order, standing_order: standing_order2, order_cycle: order_cycle1) } # Standing Order Paused
    let!(:proxy_order3) { create(:proxy_order, standing_order: standing_order3, order_cycle: order_cycle1) } # Standing Order Cancelled
    let!(:proxy_order4) { create(:proxy_order, standing_order: standing_order4, order_cycle: order_cycle1) } # Standing Order Begins after OC close
    let!(:proxy_order5) { create(:proxy_order, standing_order: standing_order5, order_cycle: order_cycle1) } # Standing Order Ends before OC close
    let!(:proxy_order6) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, canceled_at: 5.minutes.ago) } # Cancelled
    let!(:proxy_order7) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago) } # Already placed
    let!(:proxy_order8) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1) } # OK

    it "only returns not_canceled proxy_orders for the relevant order cycle" do
      proxy_orders = job.send(:placeable_proxy_orders_for, order_cycle1)
      expect(proxy_orders).to include proxy_order8
      expect(proxy_orders).to_not include proxy_order1, proxy_order2, proxy_order3, proxy_order4, proxy_order5, proxy_order6, proxy_order7
    end
  end

  describe "finding confirmable proxy orders for a particular order cycle" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 10.minutes.from_now) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now) }
    let(:standing_order2) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now, paused_at: 1.minute.ago) }
    let(:standing_order3) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 9.minutes.from_now, ends_at: 11.minutes.from_now, canceled_at: 1.minute.ago) }
    let(:standing_order4) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 11.minutes.from_now, ends_at: 20.minutes.from_now) }
    let(:standing_order5) { create(:standing_order, shop: shop, schedule: schedule, begins_at: 1.minute.ago, ends_at: 9.minutes.from_now) }
    let!(:proxy_order1) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle2, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # OC Mismatch
    let!(:proxy_order2) { create(:proxy_order, standing_order: standing_order2, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Standing Order Paused
    let!(:proxy_order3) { create(:proxy_order, standing_order: standing_order3, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Standing Order Cancelled
    let!(:proxy_order4) { create(:proxy_order, standing_order: standing_order4, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Standing Order Begins after OC close
    let!(:proxy_order5) { create(:proxy_order, standing_order: standing_order5, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Standing Order Ends before OC close
    let!(:proxy_order6) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago), canceled_at: 1.minute.ago) } # Cancelled
    let!(:proxy_order7) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order)) } # Order Incomplete
    let!(:proxy_order8) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: nil) } # No Order
    let!(:proxy_order9) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: nil, order: create(:order, completed_at: 1.minute.ago)) } # Not Placed
    let!(:proxy_order10) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, confirmed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Already Confirmed
    let!(:proxy_order11) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # OK

    it "only returns incomplete orders in the relevant order cycle that are linked to a standing order" do
      proxy_orders = job.send(:confirmable_proxy_orders_for, order_cycle1)
      expect(proxy_orders).to include proxy_order11
      expect(proxy_orders).to_not include proxy_order1, proxy_order2, proxy_order3, proxy_order4, proxy_order5
      expect(proxy_orders).to_not include proxy_order6, proxy_order7, proxy_order8, proxy_order9, proxy_order10
    end
  end

  describe "running the job" do
    context "when an order cycle has just opened" do
      let!(:order_cycle) { create(:simple_order_cycle, orders_open_at: 5.minutes.ago) }
      let!(:proxy_order) { create(:proxy_order, order_cycle: order_cycle) }

      before do
        allow(job).to receive(:placeable_proxy_orders_for) { ProxyOrder.where(id: proxy_order.id) }
      end

      it "marks placeable proxy_orders as processed by setting placed_at" do
        expect{job.perform}.to change{proxy_order.reload.placed_at}
        expect(proxy_order.placed_at).to be_within(5.seconds).of Time.now
      end

      it "enqueues a StandingOrderPlacementJob for each recently opened order_cycle" do
        expect{job.perform}.to enqueue_job StandingOrderPlacementJob
      end
    end

    context "when an order cycle has just closed" do
      let!(:order_cycle) { create(:simple_order_cycle, orders_close_at: 5.minutes.ago) }
      let!(:proxy_order) { create(:proxy_order, order_cycle: order_cycle) }

      before do
        allow(job).to receive(:confirmable_proxy_orders_for) { ProxyOrder.where(id: proxy_order.id) }
      end

      it "marks confirmable proxy_orders as processed by setting confirmed_at" do
        expect{job.perform}.to change{proxy_order.reload.confirmed_at}
        expect(proxy_order.confirmed_at).to be_within(5.seconds).of Time.now
      end

      it "enqueues a StandingOrderPlacementJob for each recently closed order_cycle" do
        expect{job.perform}.to enqueue_job StandingOrderConfirmJob
      end
    end
  end
end
