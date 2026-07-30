# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Turbo cart" do
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
    Flipper.enable(:product_grid_view)
    Flipper.enable(:turbo_cart)

    add_variant_to_order_cycle(exchange, variant)
    set_order_cycle(order, order_cycle)
    pick_order(order)
    visit shop_path
  end

  it "adds a product to the cart" do
    click_add_to_cart variant

    expect(order.reload.line_items.first.quantity).to eq(1)

    toggle_cart
    within "#cart-sidebar" do
      expect(page).to have_content "1 item in your cart"
      expect(page).to have_content product.name
      expect(page).to have_link "Checkout"
      expect(page).to have_link "Edit cart"
    end
  end

  it "changes quantities and removes items again" do
    click_add_to_cart variant, 3

    expect(order.reload.line_items.first.quantity).to eq(3)
    within "#cart-sidebar", visible: :all do
      expect(page).to have_content "3 items in your cart"
    end

    click_remove_from_cart variant, 3

    expect(order.reload.line_items).to be_empty
    within "#cart-sidebar", visible: :all do
      expect(page).to have_content "Your cart is empty"
    end
    within_variant(variant) do
      expect(page).to have_button "Add"
    end
  end

  it "caps the quantity when stock ran short in the meantime" do
    # Someone else empties the shelf while we are browsing the shop.
    variant.update!(on_hand: 1)

    click_add_to_cart variant, 2

    # The server capped the quantity and tells us about it.
    expect(page).to have_content I18n.t("js.out_of_stock.reduced_stock_available")
    expect(order.reload.line_items.first.quantity).to eq(1)

    # The widget is reset to the saved quantity.
    within_variant(variant) do
      expect(page).to have_field "quantity", with: "1"
    end
  end

  describe "group buy" do
    let(:product) { create(:simple_product, name: "Bulk Grapes", group_buy: true, on_hand: 15) }

    it "saves quantity and max quantity through the bulk buy modal" do
      click_add_bulk_to_cart variant, 2
      click_add_bulk_max_to_cart 2

      within ".reveal-modal" do
        click_button "Close"
      end
      wait_for_cart

      line_item = order.reload.line_items.first
      expect(line_item.quantity).to eq(2)
      expect(line_item.max_quantity).to eq(4)

      within_variant(variant) do
        expect(page).to have_button "2"
        expect(page).to have_button "4"
      end
    end
  end
end
