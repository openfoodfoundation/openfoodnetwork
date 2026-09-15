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

    it "recalculates enterprise fees" do
      add_enterprise_fee create(:enterprise_fee, amount: 5)

      update_variant(variant, { quantity: 1 })

      expect(order.reload.adjustment_total).to eq 5
      expect(response.body).to include 'target="cart-sidebar"'
    end
  end
end
