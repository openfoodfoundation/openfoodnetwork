# frozen_string_literal: true

require "spec_helper"

describe OrderWorkflow do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order) do
    create(:order_with_totals_and_distribution, distributor: distributor,
                                                bill_address: create(:address),
                                                ship_address: create(:address),
                                                payments: [create(:payment)])
  end

  let(:service) { described_class.new(order) }

  it "transitions the order multiple steps" do
    expect(order.state).to eq("cart")
    service.complete
    order.reload
    expect(order.state).to eq("complete")
  end

  describe "transition from delivery" do
    let!(:shipping_method_a) { create(:shipping_method, distributors: [distributor]) }
    let!(:shipping_method_b) { create(:shipping_method, distributors: [distributor]) }
    let!(:shipping_method_c) { create(:shipping_method, distributors: [distributor]) }

    before do
      # Create shipping rates for available shipping methods.
      order.shipments.each(&:refresh_rates)
    end

    it "retains delivery method of the order" do
      order.select_shipping_method(shipping_method_b.id)
      service.complete
      order.reload
      expect(order.shipping_method).to eq(shipping_method_b)
    end
  end

  context "when raising on error" do
    it "transitions the order multiple steps" do
      service.complete!
      order.reload
      expect(order.state).to eq("complete")
    end

    context "when order cannot advance to the next state" do
      let!(:order) do
        create(:order, distributor: distributor)
      end

      it "raises error" do
        expect { service.complete! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end
end
