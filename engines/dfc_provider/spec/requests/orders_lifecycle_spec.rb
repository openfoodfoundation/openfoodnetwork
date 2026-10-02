# frozen_string_literal: true

require_relative "../spec_helper"

# The swagger specs in orders_spec.rb document each endpoint on its own, using
# orders built by factories. These specs cover the lifecycle of an order that
# was created through the API itself, which is how the backorder flow uses it.
RSpec.describe "Orders lifecycle" do
  let(:user) { create(:oidc_user, email: "user@example.com") }
  let(:enterprise) { create(:distributor_enterprise, owner: user) }
  let(:variant) { create(:variant, enterprise:, on_demand: false, on_hand: 10) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:orders_url) { "/api/dfc/enterprises/#{enterprise.id}/orders" }

  before do
    login_as user
    enterprise.customers.create!(user:, email: user.email)
  end

  # A DFC order graph like the one FdcBackorderer sends.
  def order_payload(status: "dfc-v:Held", quantity: 1, product_id: supplied_product_url(variant))
    base = "http://test.host#{orders_url}"

    {
      "@context" => "https://www.datafoodconsortium.org",
      "@graph" => [
        { "@id" => base,
          "@type" => "dfc-b:Order",
          "dfc-b:hasPart" => "#{base}/OrderLines/1",
          "dfc-b:hasOrderStatus" => status },
        { "@id" => "#{base}/OrderLines/1",
          "@type" => "dfc-b:OrderLine",
          "dfc-b:quantity" => quantity,
          "dfc-b:concerns" => "#{base}/offers/1" },
        { "@id" => "#{base}/offers/1",
          "@type" => "dfc-b:Offer",
          "dfc-b:offeredItem" => product_id },
      ]
    }.to_json
  end

  def supplied_product_url(variant)
    "http://test.host/api/dfc/enterprises/#{variant.enterprise_id}/supplied_products/#{variant.id}"
  end

  def create_order!
    post orders_url, headers:, params: order_payload
    expect(response).to have_http_status(:created), response.body
    enterprise.distributed_orders.last
  end

  describe "creating an order" do
    it "creates an order that the rest of OFN recognises as placed" do
      order = create_order!

      expect(order.state).to eq "complete"
      expect(order).to be_completed
      expect(Spree::Order.complete).to include order
    end

    it "calculates the order total" do
      order = create_order!

      expect(order.item_total).to eq variant.price
      expect(order.total).to be_positive
    end

    it "reserves stock" do
      expect { create_order! }.to change { variant.reload.on_hand }.from(10).to(9)
    end

    it "doesn't become the ordering user's shopping cart" do
      create_order!

      expect(user.last_incomplete_spree_order).to be_nil
    end

    it "rejects a product of another enterprise" do
      other_variant = create(:variant, enterprise: create(:enterprise))

      post orders_url, headers:,
                       params: order_payload(product_id: supplied_product_url(other_variant))

      expect(response).to have_http_status :unprocessable_entity
      expect(response.body).to include "unknown products"
      expect(enterprise.distributed_orders).to be_empty
    end

    it "rejects a product id that isn't a supplied product URL" do
      post orders_url, headers:,
                       params: order_payload(product_id: "https://example.net/products/1")

      expect(response).to have_http_status :unprocessable_entity
      expect(enterprise.distributed_orders).to be_empty
    end
  end

  describe "completing an order" do
    it "accepts the completion the client sends at the end of the order cycle" do
      order = create_order!

      put "#{orders_url}/#{order.id}", headers:,
                                       params: order_payload(status: "dfc-v:Complete", quantity: 2)

      expect(response).to have_http_status :ok
      expect(order.reload.line_items.first.quantity).to eq 2
    end

    it "accepts a payload containing only the order" do
      order = create_order!
      body = {
        "@context" => "https://www.datafoodconsortium.org/",
        "@id" => "http://test.host#{orders_url}/#{order.id}",
        "@type" => "dfc-b:Order",
        "dfc-b:hasOrderStatus" => "dfc-v:Held",
      }.to_json

      put "#{orders_url}/#{order.id}", headers:, params: body

      expect(response).to have_http_status :ok
    end
  end

  describe "cancelling an order" do
    it "cancels an order created through this API" do
      order = create_order!

      delete "#{orders_url}/#{order.id}"

      expect(response).to have_http_status :no_content
      expect(order.reload.state).to eq "canceled"
    end

    it "reports the cancellation" do
      order = create_order!
      delete "#{orders_url}/#{order.id}"

      get "#{orders_url}/#{order.id}"

      expect(response.body).to include "dfc-v:Cancelled"
    end
  end

  describe "cancelling via the order status" do
    it "cancels the order" do
      order = create_order!

      put "#{orders_url}/#{order.id}", headers:,
                                       params: order_payload(status: "dfc-v:Cancelled")

      expect(response).to have_http_status :ok
      expect(order.reload.state).to eq "canceled"
    end

    it "returns the stock" do
      order = create_order!

      expect {
        put "#{orders_url}/#{order.id}", headers:,
                                         params: order_payload(status: "dfc-v:Cancelled")
      }.to change { variant.reload.on_hand }.from(9).to(10)
    end
  end

  describe "an invalid update" do
    it "leaves the order untouched" do
      order = create_order!
      original = order.line_items.map { |li| [li.variant_id, li.quantity] }

      unknown_product = "#{supplied_product_url(variant)}0"

      put "#{orders_url}/#{order.id}", headers:,
                                       params: order_payload(product_id: unknown_product)

      expect(response).to have_http_status :unprocessable_entity
      expect(order.reload.line_items.map { |li| [li.variant_id, li.quantity] }).to eq original
    end

    it "reports a line item the order can't hold" do
      order = create_order!

      put "#{orders_url}/#{order.id}", headers:,
                                       params: order_payload(quantity: 999)

      expect(response).to have_http_status :unprocessable_entity
      expect(response.body).to include "is out of stock"
      expect(order.reload.line_items.first.quantity).to eq 1
    end
  end
end
