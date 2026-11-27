# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Adding products to a previous order" do
  include AuthenticationHelper
  include ShopWorkflow

  let(:user) { create(:user) }
  let(:distributor) {
    create(:distributor_enterprise, with_payment_and_shipping: true, allow_order_additions: true)
  }
  let(:product) { create(:product, name: "Organic carrots", price: 10) }
  let(:variant) { product.variants.first }
  let(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
  }
  let!(:order) {
    create(:completed_order_with_totals, number: "R111111111", user:, distributor:,
                                         order_cycle:, completed_at: 2.days.ago)
  }
  let(:cart) { create(:order, user:, distributor:, order_cycle:) }

  before do
    create(:line_item, order: cart, variant:, quantity: 2)
    pick_order(cart)
    login_as user
    visit cart_path
  end

  it "adds the cart to the previous order and shows it" do
    within("#cart-container") { click_link "Checkout" }

    expect(page).to have_content "You have already confirmed an order for this order cycle."
    click_button "Yes, add to previous order"

    expect(page).to have_content "The products were added to your order #R111111111."
    expect(page).to have_content "Order #R111111111 Confirmed"
    expect(page).to have_content "Organic carrots"
  end

  it "creates a new order instead when the customer chooses so" do
    within("#cart-container") { click_link "Checkout" }

    click_link "No, create a new order"

    expect(page).to have_current_path checkout_step_path(:details)
    expect(order.reload.line_items.count).to eq 1
  end

  it "lets the customer choose which order to add to when they have several" do
    create(:completed_order_with_totals, number: "R222222222", user:, distributor:,
                                         order_cycle:, completed_at: 1.day.ago)

    within("#cart-container") { click_link "Checkout" }

    expect(page).to have_content "You have already confirmed orders for this order cycle."
    select "#R111111111", from: "Order"
    click_button "Yes, add to previous order"

    expect(page).to have_content "The products were added to your order #R111111111."
  end

  it "comes back to the shop from the order page and selects that order at checkout" do
    create(:completed_order_with_totals, number: "R222222222", user:, distributor:,
                                         order_cycle:, completed_at: 1.day.ago)

    visit order_path(order)
    click_link "Add products"

    expect(page).to have_current_path(
      enterprise_shop_path(distributor, order_cycle_id: order_cycle.id, add_to_order: "R111111111")
    )
    visit cart_path
    within("#cart-container") { click_link "Checkout" }

    # The order they came from, not the most recent one.
    expect(page).to have_select "Order", selected: "#R111111111 ($10.00)"
  end

  it "shows the balance due when the order was already paid" do
    # The order has one $10 item and no fees. The customer pays it in full.
    expect(order.total).to eq 10
    create(:payment, :completed, order:, amount: 10)
    order.update_order!
    expect(order.reload.payment_state).to eq "paid"

    # The cart holds 2 carrots at $10.
    within("#cart-container") { click_link "Checkout" }
    click_button "Yes, add to previous order"

    expect(page).to have_content "The products were added to your order #R111111111."
    # $10 + $20 = $30, of which $10 is paid.
    expect(order.reload.total).to eq 30
    within("#amount-paid") { expect(page).to have_content "$10.00" }
    within("#balance-due") { expect(page).to have_content "$20.00" }
  end
end
