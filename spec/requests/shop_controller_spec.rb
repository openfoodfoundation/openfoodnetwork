# frozen_string_literal: true

RSpec.describe "Shop" do
  include_context "session helper"

  let(:pm) { create(:payment_method) }
  let(:sm) { create(:shipping_method) }
  let(:distributor) {
    create(:distributor_enterprise, payment_methods: [pm], shipping_methods: [sm])
  }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
  let(:order) { create(:order, distributor:, order_cycle:) }

  describe "GET /shop/product_modal" do
    before do
      session_hash[:order_id] = order.id
    end

    context "when the product is distributed by the current shop" do
      it "renders modal HTML with product details and Stimulus attributes" do
        product = create(:simple_product, description: "<p>Fresh apples</p>")
        product.properties << create(:property, name: "Organic")
        order_cycle.exchanges.outgoing.first.variants << product.variants.first

        get "/shop/product_modal", params: {
          product_id: product.id,
          order_cycle_id: order_cycle.id
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(product.name)
        expect(response.body).to include(product.variants.first.supplier.name)
        expect(response.body).to include(
          "data-controller=\"modal shop-product-modal\""
        )
        expect(response.body).to include("data-modal-instant-value")
        expect(response.body).to include(
          "id=\"shop-product-modal-#{product.id}\""
        )
        expect(response.body).to include("<p>Fresh apples</p>")
        expect(response.body).to include("cap color")
        expect(response.body).to include("ofn-thumbnail-carousel")
      end
    end

    context "when the product is not distributed by the current shop" do
      it "returns not found" do
        product = create(:simple_product)

        get "/shop/product_modal", params: {
          product_id: product.id,
          order_cycle_id: order_cycle.id
        }

        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context "when no open order cycle exists" do
      it "returns not found" do
        product = create(:simple_product)
        order_cycle.update!(
          orders_open_at: 1.week.ago, orders_close_at: 1.day.ago
        )

        get "/shop/product_modal", params: {
          product_id: product.id,
          order_cycle_id: order_cycle.id
        }

        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
