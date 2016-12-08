require 'spec_helper'

describe StandingOrderSyncJob do
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
  let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
  let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }

  let(:job) { StandingOrderSyncJob.new(schedule1) }

  describe "finding standing_orders for the specified schedule" do
    let!(:standing_order1) { create(:standing_order_with_items, shop: shop, schedule: schedule1) }
    let!(:standing_order2) { create(:standing_order_with_items, shop: shop, schedule: schedule1, paused_at: 1.minute.ago) }
    let!(:standing_order3) { create(:standing_order_with_items, shop: shop, schedule: schedule1, canceled_at: 1.minute.ago) }
    let!(:standing_order4) { create(:standing_order_with_items, shop: shop, schedule: schedule1, begins_at: 1.minute.from_now) }
    let!(:standing_order5) { create(:standing_order_with_items, shop: shop, schedule: schedule1, ends_at: 1.minute.ago) }

    it "only returns incomplete orders in the relevant order cycle that are linked to a standing order" do
      standing_orders = job.send(:standing_orders)
      expect(standing_orders).to include standing_order1, standing_order2, standing_order4
      expect(standing_orders).to_not include standing_order3, standing_order5
    end
  end

  describe "performing the job" do
    let(:schedule) { double(:schedule) }
    let(:standing_order) { double(:standing_order) }
    let(:form) { double(:form) }
    let!(:job) { StandingOrderSyncJob.new(schedule) }

    before do
      allow(job).to receive(:standing_orders) { [standing_order] }
      allow(StandingOrderForm).to receive(:new) { form }
      allow(form).to receive(:initialise_orders!)
      allow(form).to receive(:remove_obsolete_orders!)
    end

    it "calls initialize_orders! and remove_obsolete_orders! on each form" do
      job.perform
      expect(form).to have_received(:initialise_orders!).once
      expect(form).to have_received(:remove_obsolete_orders!).once
    end
  end
end
