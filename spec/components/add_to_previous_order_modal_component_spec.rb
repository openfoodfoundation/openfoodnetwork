# frozen_string_literal: true

RSpec.describe AddToPreviousOrderModalComponent, type: :component do
  let(:order) { create(:completed_order_with_totals, number: "R111111111") }

  it "offers to add the products to the previous order, or to create a new order" do
    render_inline(described_class.new(orders: [order]))

    expect(page).to have_content "You have already confirmed an order for this order cycle. " \
                                 "Do you want to add these products to the previous order?"
    expect(page).to have_field "order_number", type: :hidden, with: "R111111111"
    expect(page).to have_button "Yes, add to previous order"
    expect(page).to have_link "No, create a new order", href: "/checkout/details"
  end

  it "lets the customer choose the order when they have several, in the given order" do
    other_order = create(:completed_order_with_totals, number: "R222222222")

    render_inline(described_class.new(orders: [other_order, order]))

    expect(page).to have_content "You have already confirmed orders for this order cycle. " \
                                 "Do you want to add these products to one of them?"
    expect(page).to have_select "Order"
    # The browser selects the first option: the most recent order (see Spree::OrdersHelper).
    expect(page.all("option").map(&:text)).to eq ["#R222222222 ($10.00)", "#R111111111 ($10.00)"]
  end
end
