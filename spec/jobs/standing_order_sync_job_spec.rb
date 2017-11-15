require 'spec_helper'

describe StandingOrderSyncJob do
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
  let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
  let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }

  let(:job) { StandingOrderSyncJob.new(schedule1) }

  describe "performing the job" do
    let(:schedule) { double(:schedule) }
    let(:standing_order) { double(:standing_order) }
    let(:syncer) { double(:syncer) }
    let!(:job) { StandingOrderSyncJob.new(schedule) }

    before do
      allow(job).to receive(:standing_orders) { [standing_order] }
      allow(OpenFoodNetwork::ProxyOrderSyncer).to receive(:new) { syncer }
      allow(syncer).to receive(:sync!)
    end

    it "calls sync!" do
      job.perform
      expect(syncer).to have_received(:sync!).once
    end
  end
end
