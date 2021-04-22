# frozen_string_literal: true

require "spec_helper"

describe "spree/shared/_order_details.html.haml" do
  include AuthenticationHelper
  helper Spree::BaseHelper
  helper CheckoutHelper
  helper OrderHelper

  let(:order) { create(:completed_order_with_fees) }

  before do
    assign(:order, order)
    allow(view).to receive_messages(
      order: order,
      current_order: order
    )
  end

  it "shows how the order is paid for" do
    order.payments.first.payment_method.update(name: "Bartering")

    render

    expect(rendered).to have_content("Paying via:\nBartering")
  end

  it "displays payment methods safely" do
    order.payments.first.payment_method.update(name: "Bar<script>evil</script>ter&rarr;ing")

    render

    expect(rendered).to have_content("Paying via:\nBar<script>evil</script>ter&rarr;ing")
  end

  it "shows the last used payment method" do
    first_payment = order.payments.first
    second_payment = create(
      :payment,
      order: order,
      payment_method: create(:payment_method, name: "Cash")
    )
    third_payment = create(
      :payment,
      order: order,
      payment_method: create(:payment_method, name: "Credit")
    )
    first_payment.update_column(:created_at, 3.days.ago)
    second_payment.update_column(:created_at, 2.days.ago)
    third_payment.update_column(:created_at, 1.day.ago)
    order.payments.reload

    render

    expect(rendered).to have_content("Paying via:\nCredit")
  end
end
