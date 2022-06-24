# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleShippingMethod do
  it "is valid if the shipping method belongs to one of the order cycle distributors" do
    shipping_method = create(:shipping_method)
    enterprise = create(:enterprise, shipping_methods: [shipping_method])
    order_cycle = create(:simple_order_cycle, distributors: [enterprise])

    order_cycle_shipping_method = OrderCycleShippingMethod.new(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )

    expect(order_cycle_shipping_method).to be_valid
  end

  it "is not valid if the shipping method does not belong to one of the order cycle distributors" do
    shipping_method = create(:shipping_method)
    enterprise = create(:enterprise)
    order_cycle = create(:simple_order_cycle, distributors: [enterprise])

    order_cycle_shipping_method = OrderCycleShippingMethod.new(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )

    expect(order_cycle_shipping_method).not_to be_valid
    expect(order_cycle_shipping_method.errors.to_a).to eq [
      "Shipping method must be from a distributor on the order cycle"
    ]
  end
end
