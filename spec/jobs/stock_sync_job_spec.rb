# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StockSyncJob do
  let(:order) { create(:order_with_totals, distributor:) }
  let(:distributor) { build(:enterprise, owner: user) }
  let(:user) { build(:testdfc_user) }
  let(:beans) { order.variants.first }
  let(:beans_retail_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:catalog_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
  }

  describe ".sync_linked_catalogs" do
    subject { StockSyncJob.sync_linked_catalogs(order) }
    it "ignores products without semantic link" do
      expect { subject }.not_to enqueue_job(StockSyncJob)
    end

    it "enqueues backorder" do
      beans.semantic_links << SemanticLink.new(
        semantic_id: beans_retail_link
      )

      expect { subject }.to enqueue_job(StockSyncJob)
        .with(user, catalog_link)
    end

    it "reports errors" do
      expect(order).to receive(:variants).and_raise("test error")
      expect(Bugsnag).to receive(:notify).and_call_original

      expect { subject }.not_to raise_error
    end
  end

  describe "#perform" do
    subject { StockSyncJob.perform_now(user, catalog_link) }

    before do
      distributor.save!
      user.enterprises << distributor
      beans.update!(supplier: distributor)
      beans.semantic_links << SemanticLink.new(semantic_id: beans_retail_link)
    end

    it "updates stock" do
      expect { VCR.use_cassette(:fdc_catalog) { subject } }.to change {
        beans.on_demand
      }.from(false).to(true)
    end
  end
end
