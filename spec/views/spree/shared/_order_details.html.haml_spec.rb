require "spec_helper"

describe "spree/shared/_order_details.html.haml" do
  include AuthenticationWorkflow
  helper Spree::BaseHelper

  let(:order) { create(:completed_order_with_fees) }

  before do
    assign(:order, order)
    allow(view).to receive_messages(
      order: order,
      current_order: order,
    )
  end

  it "shows how the order is paid for" do
    order.payments.first.payment_method.name = "Bartering"

    render

    expect(rendered).to have_content("Paying via: Bartering")
  end
end
