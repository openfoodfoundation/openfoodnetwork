# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FdcBackorderer do
  let(:order) { create(:completed_order_with_totals) }
  let(:account) {
    OidcAccount.new(
      uid: "testdfc@protonmail.com",
      refresh_token: ENV.fetch("OPENID_REFRESH_TOKEN"),
      updated_at: 1.day.ago,
    )
  }

  before do
    order.distributor.owner.oidc_account = account
  end

  describe "#find_or_build_order" do
    it "builds an order object" do
      account.updated_at = Time.zone.now
      stub_request(:get, FdcBackorderer::FDC_ORDERS_URL)
        .to_return(status: 200, body: "{}")

      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to match %r{^https.*/\#$}
      expect(backorder.lines).to eq []
    end

    it "finds an order object", vcr: true do
      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to match %r{^https.*/[0-9]+$}
      expect(backorder.lines.count).to eq 1
    end

    it "completes an order", vcr: true do
      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to match %r{^https.*/[0-9]+$}
      expect(backorder.lines.count).to eq 1

      subject.complete_order(order, backorder)

      remaining_open_order = subject.find_or_build_order(order)
      expect(remaining_open_order.semanticId).not_to eq backorder.semanticId
    end
  end

  describe "#find_or_build_order_line" do
    it "add quantity to an existing line item", vcr: true do
      catalog = BackorderJob.load_catalog(order.distributor.owner)
      backorder = subject.find_or_build_order(order)
      existing_line = backorder.lines[0]

      # The FDC API returns different ids for the same offer.
      # In order to test that we can still match it, we are retrieving
      # the catalog offer here which is different to the offer on the
      # existing order line.
      ordered_product = existing_line.offer.offeredItem
      catalog_product = catalog.find do |i|
        i.semanticId == ordered_product.semanticId
      end
      catalog_offer = BackorderJob.offer_of(catalog_product)

      # The API response is missing this connection:
      catalog_offer.offeredItem = catalog_product

      # Just confirm that we got good test data from the API:
      expect(backorder.semanticId).to match %r{^https.*/[0-9]+$}
      expect(backorder.lines.count).to eq 1

      found_line = subject.find_or_build_order_line(backorder, catalog_offer)

      expect(found_line).to eq existing_line
    end
  end
end
