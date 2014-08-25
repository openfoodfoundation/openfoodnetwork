require 'open_food_network/permissions'

module OpenFoodNetwork
  describe Permissions do
    let(:user) { double(:user) }
    let(:permissions) { Permissions.new(user) }
    let(:producer) { double(:enterprise) }

    describe "finding producers that can be added to an order cycle" do
      it "returns managed producers" do
        permissions.stub(:managed_producers) { [producer] }
        permissions.order_cycle_producers.should == [producer]
      end
    end
  end
end
