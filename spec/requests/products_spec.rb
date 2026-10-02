# frozen_string_literal: true

RSpec.describe ProductsController do
  include_context "session helper"

  describe "GET /:enterprise_permalink/products/:id" do
    let(:enterprise) {
      create(:distributor_enterprise, name: "The Garlic Guru", with_payment_and_shipping: true)
    }
    let(:product) {
      create(:product, enterprise_id: enterprise.id, name: "Garlic", price: 3.21)
    }
    let(:page) { Capybara::Node::Simple.new(response.body) }

    context "with one order cycle on offer" do
      let!(:order_cycle) {
        create(:simple_order_cycle, distributors: [enterprise], coordinator: enterprise,
                                    variants: product.variants)
      }

      it "shows one product with its variants" do
        get enterprise_product_path(enterprise, product)

        expect(response).to have_http_status :ok
        expect(page.title).to eq "Garlic from The Garlic Guru\n - Open Food Network"
        expect(page).to have_selector ".product-header", text: "Garlic"
        expect(page).to have_selector ".product-header", text: /from\s+The Garlic Guru/
      end

      # Smoke test over the ProductsRenderer -> ViewData -> ShopVariantListComponent chain,
      # which a component spec can't cover because it builds its own value objects.
      it "lists each variant with its price and an add to cart widget" do
        get enterprise_product_path(enterprise, product)

        expect(page).to have_selector ".variant-list li", count: 1
        expect(page).to have_content "$3.21"
        expect(page).to have_selector ".unit-price"
        expect(page).to have_selector "#variant-#{product.variants.first.id}"
      end

      # Looking is not shopping. The add buttons carry the shop and order cycle instead,
      # so that the first add can start the cart off.
      it "doesn't start a cart for a visitor who only looks" do
        expect { get enterprise_product_path(enterprise, product) }
          .not_to change { Spree::Order.count }

        expect(page).to have_selector(
          "[data-add-to-cart-url-value*='order_cycle_id=#{order_cycle.id}']"
        )
        expect(page).to have_selector(
          "[data-add-to-cart-url-value*='enterprise_permalink=#{enterprise.permalink}']"
        )
      end

      # A variant of another shop's order cycle isn't on offer here.
      it "leaves out variants that aren't distributed by this shop" do
        other_variant = create(:variant, product:)
        create(:simple_order_cycle, variants: [other_variant])

        get enterprise_product_path(enterprise, product)

        expect(page).to have_selector ".variant-list li", count: 1
        expect(page).not_to have_selector "#variant-#{other_variant.id}"
      end
    end

    context "without an order cycle on offer" do
      it "says that the product is unavailable" do
        get enterprise_product_path(enterprise, product)

        expect(response).to have_http_status :ok
        expect(page).to have_content "Garlic"
        expect(page).to have_content "This product is currently unavailable."
        expect(page).not_to have_selector ".variant-list"
      end
    end

    context "with several order cycles to choose from" do
      before do
        2.times do
          create(:simple_order_cycle, distributors: [enterprise], coordinator: enterprise,
                                      variants: product.variants)
        end
      end

      it "asks the shopper to choose one first" do
        get enterprise_product_path(enterprise, product)

        expect(page).to have_content "Please choose an order cycle"
        expect(page).not_to have_selector ".variant-list"
      end

      # There's nothing to point the cart at until the shopper chooses.
      it "doesn't start shopping here" do
        expect { get enterprise_product_path(enterprise, product) }
          .not_to change { Spree::Order.count }
      end
    end
  end

  describe "POST /:enterprise_permalink/products/:id/order_cycle" do
    let(:enterprise) {
      create(:distributor_enterprise, name: "The Garlic Guru", with_payment_and_shipping: true)
    }
    let(:product) { create(:product, enterprise_id: enterprise.id, name: "Garlic") }
    let!(:order_cycle) {
      create(:simple_order_cycle, distributors: [enterprise], coordinator: enterprise,
                                  variants: product.variants)
    }

    it "starts shopping at this shop in the chosen order cycle" do
      post order_cycle_enterprise_product_path(enterprise, product),
           params: { order_cycle_id: order_cycle.id }

      expect(response).to redirect_to enterprise_product_path(enterprise, product)
      expect(Spree::Order.last).to have_attributes(
        distributor: enterprise, order_cycle:
      )
    end

    it "ignores an order cycle that this shop doesn't offer" do
      other_order_cycle = create(:simple_order_cycle)

      post order_cycle_enterprise_product_path(enterprise, product),
           params: { order_cycle_id: other_order_cycle.id }

      expect(response).to redirect_to enterprise_product_path(enterprise, product)
      expect(Spree::Order.last&.order_cycle).to be_nil
    end

    # Shopping at another shop starts a new cart there, as it does on the shopfront.
    it "empties a cart of another shop" do
      other_shop = create(:distributor_enterprise)
      other_order = create(:order_with_line_items, distributor: other_shop, line_items_count: 1)
      session_hash[:order_id] = other_order.id

      post order_cycle_enterprise_product_path(enterprise, product),
           params: { order_cycle_id: order_cycle.id }

      expect(other_order.reload).to have_attributes(
        distributor: enterprise, order_cycle:, line_items: []
      )
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
