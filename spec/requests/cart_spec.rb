# frozen_string_literal: true

RSpec.describe "Cart" do
  include ShopWorkflow

  describe "PATCH /cart/variants/:variant_id" do
    let(:order_cycle) { create(:order_cycle) }
    let(:distributor) { order_cycle.distributors.first }
    let(:order) { create(:order, order_cycle:, distributor:) }
    let(:variant) { order_cycle.variants_distributed_by(distributor).first }

    before { pick_order(order) }

    def update_variant(variant, params)
      patch variant_cart_path(variant.id), params:,
                                           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "adds the variant and responds with the updated cart sidebar" do
      update_variant(variant, { quantity: 2 })

      expect(response).to have_http_status :ok
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
      expect(response.body).to include 'target="cart-sidebar"'
      expect(response.body).to include "2 items in your cart"

      expect(order.line_items.reload.first.quantity).to eq 2
    end

    it "updates and removes line items" do
      add_product_to_cart(order, variant.product, quantity: 3)

      update_variant(variant, { quantity: 1 })
      expect(order.line_items.reload.first.quantity).to eq 1

      update_variant(variant, { quantity: 0 })
      expect(order.line_items.reload).to be_empty
      expect(response.body).to include "Your cart is empty"
    end

    it "caps the quantity at the available stock and notifies the customer" do
      variant.update!(on_demand: false, on_hand: 3)

      update_variant(variant, { quantity: 5 })

      expect(order.line_items.reload.first.quantity).to eq 3

      # The add to cart widget is reset to the saved quantity and the
      # out of stock modal is shown.
      expect(response.body).to include "target=\"variant-#{variant.id}\""
      expect(response.body).to include 'target="out-of-stock-modal"'
      expect(response.body).to include "Reduced stock available"
    end

    it "notifies when the stock of other cart items ran short" do
      other_variant = create(:variant, on_demand: false, on_hand: 5)
      create(:line_item, order:, variant: other_variant, quantity: 5)
      other_variant.update!(on_hand: 2)

      update_variant(variant, { quantity: 1 })

      # The other item's quantity is capped, its widget reset and the
      # out of stock modal is shown.
      expect(order.line_items.reload.find_by(variant_id: other_variant.id).quantity).to eq 2
      expect(response.body).to include "target=\"variant-#{other_variant.id}\""
      expect(response.body).to include 'target="out-of-stock-modal"'
      expect(response.body).to include "Reduced stock available"
    end

    it "leaves the widget alone when stock suffices" do
      update_variant(variant, { quantity: 2 })

      expect(response.body).not_to include 'target="variant-'
      expect(response.body).not_to include 'target="out-of-stock-modal"'
    end

    it "responds with an error when the variant is not in the distribution" do
      other_variant = create(:variant)

      update_variant(other_variant, { quantity: 1 })

      expect(response).to have_http_status :unprocessable_entity
      expect(response.body).to include 'target="flashes"'
      expect(response.body)
        .to include "That product is not available from the chosen distributor or order cycle."
      expect(order.line_items.reload).to be_empty
    end

    context "with a plain HTML request" do
      it "redirects back after saving" do
        patch variant_cart_path(variant.id), params: { quantity: 1 }

        expect(response).to redirect_to "/cart"
        expect(order.line_items.reload.first.quantity).to eq 1
      end

      it "redirects back with a flash message on error" do
        other_variant = create(:variant)

        patch variant_cart_path(other_variant.id),
              params: { quantity: 1 },
              headers: { "HTTP_REFERER" => "http://test.host/shop" }

        expect(response).to redirect_to "/shop"
        expect(flash[:error])
          .to eq "That product is not available from the chosen distributor or order cycle."
        expect(order.line_items.reload).to be_empty
      end
    end

    it "saves the max quantity of group buy variants" do
      variant.product.update!(group_buy: true)

      update_variant(variant, { quantity: 2, max_quantity: 4 })

      line_item = order.line_items.reload.first
      expect(line_item.quantity).to eq 2
      expect(line_item.max_quantity).to eq 4
    end

    it "does not cap the max quantity of group buy variants at the available stock" do
      variant.product.update!(group_buy: true)
      variant.update!(on_demand: false, on_hand: 3)

      update_variant(variant, { quantity: 2, max_quantity: 10 })

      line_item = order.line_items.reload.first
      expect(line_item.quantity).to eq 2
      expect(line_item.max_quantity).to eq 10
    end

    it "keeps the saved max quantity when re-rendering a capped group buy widget" do
      variant.product.update!(group_buy: true)
      variant.update!(on_demand: false, on_hand: 3)
      update_variant(variant, { quantity: 2, max_quantity: 10 })

      update_variant(variant, { quantity: 5, max_quantity: 10 })

      expect(order.line_items.reload.first.quantity).to eq 3
      expect(response.body).to include "target=\"variant-#{variant.id}\""
      expect(response.body).to match(/data-add-to-cart-target=.maxQuantity.[^>]*value=.10./)
    end

    # A product page can be a shopper's first visit to a shop, so its add buttons name
    # the shop and order cycle they belong to.
    context "when the request names a shop and order cycle" do
      # Only order cycles the shop is ready to take orders in count, the same ones the
      # product page lists.
      before do
        create(:payment_method, distributors: [distributor])
        create(:shipping_method, distributors: [distributor])
      end

      def add_at_shop(variant, shop, order_cycle)
        update_variant(variant, { quantity: 1, enterprise_permalink: shop.permalink,
                                  order_cycle_id: order_cycle.id })
      end

      it "starts an empty cart off at that shop" do
        order.update!(distributor: nil, order_cycle: nil)

        add_at_shop(variant, distributor, order_cycle)

        expect(order.reload).to have_attributes(distributor:, order_cycle:)
        expect(order.line_items.first.quantity).to eq 1
      end

      # Someone else's shop can't take over a cart that's being filled.
      it "leaves a cart with something in it where it is" do
        add_product_to_cart(order, variant.product, quantity: 1)
        other_order_cycle = create(:order_cycle)
        other_shop = other_order_cycle.distributors.first
        other_variant = other_order_cycle.variants_distributed_by(other_shop).first

        add_at_shop(other_variant, other_shop, other_order_cycle)

        expect(order.reload).to have_attributes(distributor:, order_cycle:)
        expect(response.body)
          .to include "That product is not available from the chosen distributor or order cycle."
      end

      it "ignores an order cycle that the shop doesn't offer" do
        order.update!(distributor: nil, order_cycle: nil)
        other_order_cycle = create(:order_cycle)

        add_at_shop(variant, distributor, other_order_cycle)

        expect(order.reload.order_cycle).to be_nil
        expect(order.line_items).to be_empty
      end
    end

    it "recalculates enterprise fees" do
      add_enterprise_fee create(:enterprise_fee, amount: 5)

      update_variant(variant, { quantity: 1 })

      expect(order.reload.adjustment_total).to eq 5
      expect(response.body).to include 'target="cart-sidebar"'
    end
  end

  describe "POST /cart/add_to_order" do
    let(:user) { create(:user) }
    let(:distributor) {
      create(:distributor_enterprise, with_payment_and_shipping: true, allow_order_additions: true)
    }
    let(:variant) { create(:variant, on_demand: false, on_hand: 5) }
    let(:order_cycle) {
      create(:simple_order_cycle, distributors: [distributor], variants: [variant])
    }
    let(:order) {
      create(:completed_order_with_totals, number: "R123456789", user:, distributor:, order_cycle:)
    }
    let(:cart) { create(:order, user:, distributor:, order_cycle:) }

    before do
      create(:line_item, order: cart, variant:, quantity: 2)
      pick_order(cart)
      sign_in user
    end

    def add_to_order(order)
      post add_to_order_cart_path, params: { order_number: order.number }
    end

    it "adds the cart's items to the order and shows the order" do
      add_to_order(order)

      expect(response).to redirect_to order_path(order)
      expect(flash[:success]).to eq "The products were added to your order #R123456789."
      expect(order.reload.find_line_item_by_variant(variant).quantity).to eq 2
      expect(cart.reload.line_items).to be_empty
    end

    it "reduces an item that sold out in the meantime and shows what changed instead" do
      variant.update!(on_hand: 1)

      add_to_order(order)

      expect(response).to redirect_to cart_path
      expect(cart.reload.line_items.first.quantity).to eq 1
      expect(order.reload.find_line_item_by_variant(variant)).to be_nil

      follow_redirect!
      expect(response.body).to include "Reduced stock available"
      expect(response.body).to include "now only has 1 remaining."
    end

    it "keeps the cart when an item sells out between the stock check and adding it" do
      variant.update!(on_hand: 1)
      # The stock check still saw enough stock: the item sold out right after it.
      allow(Orders::CheckStockService).to receive(:new)
        .and_return(instance_double(Orders::CheckStockService, sufficient_stock?: true))

      add_to_order(order)

      expect(response).to redirect_to cart_path
      expect(cart.reload.line_items.first.quantity).to eq 2
      expect(order.reload.find_line_item_by_variant(variant)).to be_nil

      follow_redirect!
      expect(response.body).to include "An item in your cart has become unavailable. " \
                                       "Please update the selected quantities."
    end

    it "removes an item that is now out of stock and shows what changed instead" do
      variant.update!(on_hand: 0)

      add_to_order(order)

      expect(response).to redirect_to cart_path
      expect(cart.reload.line_items).to be_empty

      follow_redirect!
      expect(response.body).to include "is now out of stock."
    end

    it "doesn't add to someone else's order" do
      other_order = create(:completed_order_with_totals, distributor:, order_cycle:)

      add_to_order(other_order)

      expect(response).to redirect_to cart_path
      expect(flash[:error]).to eq "Sorry, the products couldn't be added to that order."
      expect(other_order.reload.find_line_item_by_variant(variant)).to be_nil
      expect(cart.reload.line_items.count).to eq 1
    end

    it "doesn't add to an order when the shop doesn't allow items to be added" do
      distributor.update!(allow_order_additions: false)

      add_to_order(order)

      expect(response).to redirect_to cart_path
      expect(flash[:error]).to eq "Sorry, the products couldn't be added to that order."
      expect(order.reload.find_line_item_by_variant(variant)).to be_nil
    end

    it "doesn't add a guest's cart to an order" do
      sign_out user

      add_to_order(order)

      expect(response).to redirect_to cart_path
      expect(flash[:error]).to eq "Sorry, the products couldn't be added to that order."
      expect(order.reload.find_line_item_by_variant(variant)).to be_nil
    end
  end
end
