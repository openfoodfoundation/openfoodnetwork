# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcCatalog do
  subject(:catalog) { DfcCatalog.new(fdc_catalog_graph) }
  let(:fdc_catalog_graph) {
    VCR.use_cassette(:fdc_catalog) { broker.catalog }
  }
  let(:broker) { FdcOfferBroker.new(user, catalog_url) }
  let(:user) { build(:testdfc_user) }
  let(:catalog_url) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
  }

  describe "#products" do
    let(:products) { catalog.products }

    it "returns only products" do
      expect(products.count).to eq 4
      expect(products.map(&:semanticType).uniq).to eq ["dfc-b:SuppliedProduct"]
    end
  end
end
