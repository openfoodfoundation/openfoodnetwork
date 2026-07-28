# frozen_string_literal: true

RSpec.describe "spree/shared/_shipment_pickup_details.html.haml" do
  let(:order) { create(:completed_order_with_fees) }

  it "shows the shipping method name and pickup time" do
    render partial: "spree/shared/shipment_pickup_details", locals: { order: }

    expect(rendered).to have_content(order.shipping_method.name)
  end

  it "does not error when the order has no shipments" do
    # Removing the last line item of a completed order can destroy its only
    # shipment (see Spree::LineItem#update_inventory_before_destroy), leaving
    # order.shipping_method nil. Rendering this partial must not blow up in
    # that case (regression test for the 500 seen on spree/orders#show).
    order.shipments.destroy_all

    expect { render partial: "spree/shared/shipment_pickup_details", locals: { order: } }.
      not_to raise_error

    expect(rendered).to have_content(I18n.t(:order_pickup_time))
  end
end
