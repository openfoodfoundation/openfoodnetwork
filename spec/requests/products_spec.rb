# frozen_string_literal: true

RSpec.describe ProductsController do
  include_context "session helper"

  describe "GET /:enterprise_permalink/products/:id" do
    let(:enterprise) { create(:enterprise, name: "The Garlic Guru") }
    let(:product) { create(:product, enterprise_id: enterprise.id, name: "Garlic") }
    let(:page) { Capybara::Node::Simple.new(response.body) }

    it "shows one product with its variants" do
      get enterprise_product_path(enterprise, product)
      expect(response).to have_http_status :ok
      expect(page.title).to eq "Garlic from The Garlic Guru\n - Open Food Network"
      expect(response.body).to include "Garlic"
    end
  end

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

    # Smoke test over the whole ProductsRenderer -> ViewData -> ProductTileComponent chain,
    # which a component spec can't cover because it builds its own value objects.
    it "renders the product details in each tile" do
      get order_cycle_products_path(order_cycle.id)

      expect(response.body).to include variants.first.producer.name
      expect(response.body).to include "unit-price"
      expect(response.body).to include "$19.99"
    end
  end
end
