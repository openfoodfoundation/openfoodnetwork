# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcCatalog do
  subject(:catalog) {
    VCR.use_cassette(:fdc_catalog) {
      DfcCatalog.load(user, catalog_url)
    }
  }
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

  describe "#apply_wholesale_values!" do
    let(:offer) { beans.catalogItems.first.offers.first }
    let(:catalog_item) { beans.catalogItems.first }
    let(:beans) { catalog.item(beans_id) }
    let(:beans_id) {
      "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
    }

    it "changes price of retail variants" do
      expect { catalog.apply_wholesale_values! }.to change {
        offer.price.value.to_f.round(2)
      }.from(2.09).to(1.57) # 18.85 wholesale price divided by 12
    end

    it "changes stock level of retail variant's catalog item" do
      expect { catalog.apply_wholesale_values! }.to change {
        catalog_item.stockLimitation
      }.from("-1").to(-12)
    end

    it "changes stock level of retail variant's offer" do
      wholesale_offer = catalog.item(
        "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466500403/Offer"
      )
      wholesale_offer.stockLimitation = 2

      expect { catalog.apply_wholesale_values! }.to change {
        offer.stockLimitation
      }.from(nil).to(24)
    end
  end
end
