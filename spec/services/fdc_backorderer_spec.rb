# frozen_string_literal: true

RSpec.describe FdcBackorderer do
  let(:subject) { FdcBackorderer.new(order.distributor.owner, urls) }
  let(:urls) { FdcUrlBuilder.new(product_link) }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
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

    # Build a new order when no open one is found:
    order.order_cycle = create(:order_cycle, distributors: [order.distributor])
    backorder = subject.find_or_build_order(order)
    expect(backorder.semanticId).to eq urls.orders_url
    expect(backorder.lines).to eq []

    # Add items and place the new order:
    catalog = DfcCatalog.load(order.distributor.owner, urls.catalog_url)
    product = catalog.products.first
    offer = FdcOfferBroker.new(nil).offer_of(product)
    line = subject.find_or_build_order_line(backorder, offer)
    line.quantity = 3
    placed_order = subject.send_order(backorder)

    # Give the Shopify app time to process and place the order.
    # That process seems to be async.
    sleep 10 if VCR.current_cassette.recording?

    # Without a stored semantic link, it can't look it up:
    found_backorder = subject.lookup_open_order(order)
    expect(found_backorder).to eq nil

    # But with a semantic link, it works:
    order.exchange.semantic_links.create!(semantic_id: placed_order.semanticId)
    found_backorder = subject.lookup_open_order(order)
    expect(found_backorder.semanticId).to eq placed_order.semanticId
    expect(found_backorder.lines.count).to eq 1
    expect(found_backorder.lines[0].quantity.to_i).to eq 3

    # And close the order again:
    subject.complete_order(placed_order)
    remaining_open_order = subject.find_or_build_order(order)
    expect(remaining_open_order.semanticId).to eq urls.orders_url
  end

  describe "#find_or_build_order" do
    it "builds an order object" do
      account.updated_at = Time.zone.now
      stub_request(:get, urls.orders_url)
        .to_return(status: 200, body: "{}")

      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to eq urls.orders_url
      expect(backorder.lines).to eq []
    end
  end

  describe "#find_or_build_order_line" do
    it "add quantity to an existing line item", vcr: true do
      catalog = DfcCatalog.load(order.distributor.owner, urls.catalog_url)
      backorder = subject.find_or_build_order(order)

      expect(backorder.lines.count).to eq 0

      # Add new item to the new order:
      product = catalog.products.first
      offer = FdcOfferBroker.new(nil).offer_of(product)
      line = subject.find_or_build_order_line(backorder, offer)

      expect(backorder.lines.count).to eq 1
      expect(backorder.lines[0]).to eq line

      expect {
        subject.find_or_build_order_line(backorder, offer)
      }.not_to change { backorder.lines.count }

      found_line = subject.find_or_build_order_line(backorder, offer)
      expect(found_line).to eq line
    end
  end

  describe "#new?" do
    describe "without knowing URLs" do
      let(:subject) { FdcBackorderer.new(nil, nil) }

      it "recognises new orders" do
        order = DataFoodConsortium::Connector::Order.new(nil)
        expect(subject.new?(order)).to eq true
      end

      it "recognises existing orders" do
        order = DataFoodConsortium::Connector::Order.new("https://order")
        expect(subject.new?(order)).to eq false
      end
    end
  end
end
