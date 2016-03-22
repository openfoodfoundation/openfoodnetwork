require 'spec_helper'

describe CoordinatorFee do
  describe "products caching" do
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:enterprise_fee) { create(:enterprise_fee) }

    it "refreshes the products cache on change" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:order_cycle_changed).with(order_cycle)
      order_cycle.coordinator_fees << enterprise_fee
    end

    it "refreshes the products cache on destruction" do
      order_cycle.coordinator_fees << enterprise_fee
      expect(OpenFoodNetwork::ProductsCache).to receive(:order_cycle_changed).with(order_cycle)
      order_cycle.coordinator_fee_refs.first.destroy
    end
  end
end
