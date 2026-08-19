# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Turbo cart", feature: :product_grid_view do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor],
                                coordinator: create(:distributor_enterprise),
                                orders_close_at: 2.days.from_now)
  }
  let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
  let(:product) { create(:simple_product, name: "Fresh Bread", on_hand: 10) }
  let(:variant) { product.variants.first }
  let(:order) { create(:order, distributor:) }

  before do
    add_variant_to_order_cycle(exchange, variant)
    set_order_cycle(order, order_cycle)
    pick_order(order)
    visit shop_path
  end

  it "caps the quantity when stock runs short in the meantime" do
    # Someone else empties the shelf while we are browsing the shop.
    variant.update!(on_hand: 1)

    component_add(variant)
    expect(order.reload.line_items.first.quantity).to eq(1)

    # The page still offers the stock loaded with the page, so we can ask
    # for more than is available now.
    component_add_to_cart(variant)

    # The server capped the quantity and tells us about it.
    expect(page).to have_content "Reduced stock available"
    expect(order.reload.line_items.first.quantity).to eq(1)

    within("#out-of-stock") do
      click_button "Close"
    end

    # The widget is reset to the saved quantity.
    within_variant(variant) do
      expect(page).to have_selector "input.variant-quantity[value='1']"
    end

    toggle_cart
    within(".cart-sidebar") do
      expect(page).to have_content "1 item in your cart"
    end
  end
end
