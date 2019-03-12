require "spec_helper"

describe AdvanceOrderService do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order) do
    create(:order_with_totals_and_distribution, distributor: distributor,
                                                bill_address: create(:address),
                                                ship_address: create(:address))
  end

  let(:service) { described_class.new(order) }

  it "transitions the order multiple steps" do
    expect(order.state).to eq("cart")
    service.call
    order.reload
    expect(order.state).to eq("complete")
  end

  describe "transition from delivery" do
    let!(:shipping_method_a) { create(:shipping_method, distributors: [ distributor ]) }
    let!(:shipping_method_b) { create(:shipping_method, distributors: [ distributor ]) }
    let!(:shipping_method_c) { create(:shipping_method, distributors: [ distributor ]) }

    before do
      # Create shipping rates for available shipping methods.
      order.shipments.each(&:refresh_rates)
    end

    it "retains delivery method of the order" do
      order.select_shipping_method(shipping_method_b.id)
      service.call
      order.reload
      expect(order.shipping_method).to eq(shipping_method_b)
    end
  end
end
