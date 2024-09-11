# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FdcBackorderer do
  let(:subject) { FdcBackorderer.new(order.distributor.owner) }
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

  it "creates, finds and updates orders", vcr: true do
    # This test case contains a full order life cycle.
    # It assumes that there's no open order yet to start with.
    # After closing the order at the end, the test can be repeated live again.

    # Build a new order when no open one is found:
    order.order_cycle = build(:order_cycle)
    backorder = subject.find_or_build_order(order)
    expect(backorder.semanticId).to eq FdcBackorderer::FDC_ORDERS_URL
    expect(backorder.lines).to eq []

    # Add items and place the new order:
    catalog = BackorderJob.load_catalog(order.distributor.owner)
    product = catalog.find { |i| i.semanticType == "dfc-b:SuppliedProduct" }
    offer = FdcOfferBroker.new(nil).offer_of(product)
    line = subject.find_or_build_order_line(backorder, offer)
    line.quantity = 3
    placed_order = subject.send_order(backorder)

    # Give the Shopify app time to process and place the order.
    # That process seems to be async.
    sleep 10 if VCR.current_cassette.recording?

    # Now we can find the open order:
    found_backorder = subject.find_or_build_order(order)
    expect(found_backorder.semanticId).to eq placed_order.semanticId
    expect(found_backorder.lines.count).to eq 1
    expect(found_backorder.lines[0].quantity.to_i).to eq 3

    # And close the order again:
    subject.complete_order(placed_order)
    remaining_open_order = subject.find_or_build_order(order)
    expect(remaining_open_order.semanticId).not_to eq placed_order.semanticId
  end

  describe "#find_or_build_order" do
    it "builds an order object" do
      account.updated_at = Time.zone.now
      stub_request(:get, FdcBackorderer::FDC_ORDERS_URL)
        .to_return(status: 200, body: "{}")

      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to eq FdcBackorderer::FDC_ORDERS_URL
      expect(backorder.lines).to eq []
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
      catalog_offer = FdcOfferBroker.new(nil).offer_of(catalog_product)

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
