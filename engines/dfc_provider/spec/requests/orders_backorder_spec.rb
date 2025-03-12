# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Orders integration" do
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:supplier) {
    create(
      :distributor_enterprise, # supplier sells their products on an OFN instance
      id: 10_000, owner: user, name: "Fred's Farm",
      address: build(:address, id: 40_000),
    )
  }
  let(:product) {
    create(
      :base_product,
      id: 90_000, name: "Apple", description: "Red",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "AR", supplier:) }

  let(:distributor) {
    create(
      :distributor_enterprise, # distributor has imported supplier's product to create a copy of it
      id: 11_000, owner: user, name: "Shane's Shop",
      address: build(:address, id: 41_000),
    )
  }
  let(:distributor_product) {
    create(
      :base_product,
      id: 91_000, name: "Apple", description: "Red",
      variants: [variant],
    )
  }
  let(:distributor_variant) { build(:base_variant, id: 11_001, unit_value: 1, sku: "AR", supplier:) }

  before {
    login_as user
    product

    # TODO: create distributor product with semantic link to supplier product
  }

  describe BackorderJob do
    it "creates a product" do
      # post(enterprise_orders_path(supplier.id))
      pending "finish spec"
      # TODO: make a distributor order, and flush BackorderJob

      # A backorder to the supplier has been created
      expect(supplier.distributed_orders.count).to eq 1
    end
  end
end


RSpec.describe "ORders FdcBackorderer", type: :request do
  host = Rails.application.default_url_options[:host]

  let(:backorderer) { FdcBackorderer.new(order.distributor.owner, urls) }
  let(:urls) { FdcUrlBuilder.new(product_link) }
  let(:product_link) {
    "http://#{host}/api/dfc/enterprises/#{supplier.id}/catalog_items" #why is not acessible? normally request specs are on port 80
  }
  let(:order) { create(:completed_order_with_totals) }

  # todo: also set up supplier and product to be available on above url

  before do
    order.distributor.owner.oidc_account = build(:oidc_account)
  end

  it "creates orders", vcr: :re_record do
    # This test case contains a full order life cycle.

    # Build a new order when no open one is found:
    order.order_cycle = create(:order_cycle, distributors: [order.distributor])
    backorder = backorderer.find_or_build_order(order)
    # expect(backorder.semanticId).to eq urls.orders_url
    # expect(backorder.lines).to eq []

    # Add items and place the new order:
    catalog = DfcCatalog.load(order.distributor.owner, urls.catalog_url)
    product = catalog.products.first
    offer = FdcOfferBroker.new(nil).offer_of(product)
    line = backorderer.find_or_build_order_line(backorder, offer)
    line.quantity = 3
    placed_order = backorderer.send_order(backorder)

    # Give the  app time to process and place the order.
    # That process seems to be async.
    sleep 10 if VCR.current_cassette.recording?

    # But with a semantic link, it works:
    order.exchange.semantic_links.create!(semantic_id: placed_order.semanticId)
    found_backorder = backorderer.lookup_open_order(order)
    # expect(found_backorder.semanticId).to eq placed_order.semanticId
    # expect(found_backorder.lines.count).to eq 1
    # expect(found_backorder.lines[0].quantity.to_i).to eq 3

    # And close the order again:
    backorderer.complete_order(placed_order)
    remaining_open_order = backorderer.find_or_build_order(order)
    expect(remaining_open_order.semanticId).to eq urls.orders_url

    # Expect the supplier to have a matching order
    binding.pry
  end
end

