require 'open_food_network/last_used_address'

module OpenFoodNetwork
  describe LastUsedAddress do
    let(:email) { 'test@example.com' }
    let(:address) { 'address' }

    describe "last used bill address" do
      let(:lua) { LastUsedAddress.new(email) }
      let(:order_with_bill_address) { double(:order, bill_address: address) }
      let(:order_without_bill_address) { double(:order, bill_address: nil) }

      it "returns the bill address when present" do
        lua.stub(:recent_orders) { [order_with_bill_address] }
        lua.last_used_bill_address.should == address
      end

      it "returns nil when there's no order with a bill address" do
        lua.stub(:recent_orders) { [order_without_bill_address] }
        lua.last_used_bill_address.should be_nil
      end

      it "returns nil when there are no recent orders" do
        lua.stub(:recent_orders) { [] }
        lua.last_used_bill_address.should be_nil
      end
    end

    describe "last used ship address" do
      let(:lua) { LastUsedAddress.new(email) }
      let(:pickup) { double(:shipping_method, require_ship_address: false) }
      let(:delivery) { double(:shipping_method, require_ship_address: true) }
      let(:order_with_ship_address) { double(:order, ship_address: address, shipping_method: delivery) }
      let(:order_with_unrequired_ship_address) { double(:order, ship_address: address, shipping_method: pickup) }
      let(:order_without_ship_address) { double(:order, ship_address: nil) }

      it "returns the ship address when present" do
        lua.stub(:recent_orders) { [order_with_ship_address] }
        lua.last_used_ship_address.should == address
      end

      it "returns nil when the order doesn't require a ship address" do
        lua.stub(:recent_orders) { [order_with_unrequired_ship_address] }
        lua.last_used_ship_address.should be_nil
      end

      it "returns nil when there's no order with a ship address" do
        lua.stub(:recent_orders) { [order_without_ship_address] }
        lua.last_used_ship_address.should be_nil
      end

      it "returns nil when there are no recent orders" do
        lua.stub(:recent_orders) { [] }
        lua.last_used_ship_address.should be_nil
      end
    end
  end
end
