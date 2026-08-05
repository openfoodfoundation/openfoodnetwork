# frozen_string_literal: true

RSpec.describe ProductsController do
  include_context "session helper"

  describe "GET /order_cycle/:order_cycle_id/products" do
    let(:distributor) {
      create(:distributor_enterprise, preferred_shopfront_product_sorting_method: "by_producer")
    }
    let(:order_cycle) {
      create(:simple_order_cycle, distributors: [distributor], variants: )
    }
    let(:variants) {
      create_list(:variant, 5) do |variant, i|
        product = variant.product
        product.update!(name: "Grid product ##{i}")
      end
    }
    let(:order) { create(:order, distributor:, order_cycle:) }

    # distributor is derived from the current order
    before { session_hash[:order_id] = order.id }

    it "loads available products" do
      get order_cycle_products_path(order_cycle.id)

      expect(response).to have_http_status :ok

      expect(response.body).to include 'turbo-frame id="shop-products"'
      expect(response.body).to include "Grid product #0"
      expect(response.body).to include "Grid product #1"
      expect(response.body).to include "Grid product #2"
      expect(response.body).to include "Grid product #3"
      expect(response.body).to include "Grid product #4"
    end

    it "doesn't render add to cart widgets by default" do
      get order_cycle_products_path(order_cycle.id)

      expect(response.body).not_to include 'data-controller="add-to-cart"'
    end

    context "with the turbo cart enabled" do
      before do
        Flipper.enable(:turbo_cart)
        Flipper.enable(:product_grid_view)
      end

      it "renders an add to cart widget per variant" do
        get order_cycle_products_path(order_cycle.id)

        expect(response).to have_http_status :ok
        variants.each do |variant|
          expect(response.body).to include "variant-#{variant.id}"
          expect(response.body).to include "add-to-cart-#{variant.id}"
        end
      end
    end
  end
end
