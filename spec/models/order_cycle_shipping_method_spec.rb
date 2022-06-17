# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleShippingMethod do
  it "is valid when the shipping method is available at checkout" do
    shipping_method = create(:shipping_method, display_on: nil)
    enterprise = create(:enterprise, shipping_methods: [shipping_method])
    order_cycle = create(:simple_order_cycle, distributors: [enterprise])

    order_cycle_shipping_method = OrderCycleShippingMethod.new(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )

    expect(order_cycle_shipping_method).to be_valid

    shipping_method.display_on = "both"

    expect(order_cycle_shipping_method).to be_valid
  end

  it "is not valid when the shipping method is only available in the backoffice" do
    shipping_method = create(:shipping_method, display_on: "back_end")
    enterprise = create(:enterprise, shipping_methods: [shipping_method])
    order_cycle = create(:simple_order_cycle, distributors: [enterprise])

    order_cycle_shipping_method = OrderCycleShippingMethod.new(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )

    expect(order_cycle_shipping_method).to_not be_valid
    expect(order_cycle_shipping_method.errors.to_a).to include(
      "Shipping method must be available at checkout"
    )
  end

  it "is not valid if the order cycle is simple i.e. :sells is 'own'" do
    order_cycle = create(:sells_own_order_cycle)
    shipping_method = create(:shipping_method, distributors: [order_cycle.coordinator])

    order_cycle_shipping_method = OrderCycleShippingMethod.new(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )

    expect(order_cycle_shipping_method).to_not be_valid
    expect(order_cycle_shipping_method.errors.to_a).to include(
      "Order cycle is simple, all shipping methods are available by default and cannot be " \
      "customised"
    )
  end

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

  it "can be destroyed if the shipping method hasn't been used on any orders in the order cycle" do
    shipping_method = create(:shipping_method)
    enterprise = create(:enterprise, shipping_methods: [shipping_method])
    order_cycle = create(:simple_order_cycle, distributors: [enterprise])

    order_cycle_shipping_method = OrderCycleShippingMethod.create!(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )
    order_cycle_shipping_method.destroy

    expect(order_cycle_shipping_method).to be_destroyed
  end

  it "cannot be destroyed if the shipping method has been used on some orders in the order cycle" do
    shipping_method = create(:shipping_method)
    enterprise = create(:enterprise, shipping_methods: [shipping_method])
    order_cycle = create(:simple_order_cycle, distributors: [enterprise])
    order = create(:order_ready_for_payment, distributor: enterprise, order_cycle: order_cycle)

    order_cycle_shipping_method = OrderCycleShippingMethod.create!(
      order_cycle: order_cycle,
      shipping_method: shipping_method
    )
    order_cycle_shipping_method.destroy

    expect(order_cycle_shipping_method).not_to be_destroyed
    expect(order_cycle_shipping_method.errors.to_a).to eq [
      "This shipping method has already been selected on orders in this order cycle and cannot " \
      "be removed"
    ]
  end
end
