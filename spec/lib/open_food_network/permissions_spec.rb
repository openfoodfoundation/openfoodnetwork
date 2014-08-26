require 'open_food_network/permissions'

module OpenFoodNetwork
  describe Permissions do
    let(:user) { double(:user) }
    let(:permissions) { Permissions.new(user) }
    let(:permission) { 'one' }
    let(:e1) { create(:enterprise) }
    let(:e2) { create(:enterprise) }

    describe "finding enterprises that can be added to an order cycle" do
      before do
        permissions.stub(:managed_enterprises) { Enterprise.where('1=0') }
        permissions.stub(:related_enterprises_with) { Enterprise.where('1=0') }
      end

      it "returns managed enterprises" do
        permissions.stub(:managed_enterprises) { Enterprise.where(id: e1) }
        permissions.order_cycle_enterprises.should == [e1]
      end

      it "returns permitted enterprises" do
        permissions.stub(:related_enterprises_with) { Enterprise.where(id: e2) }
        permissions.order_cycle_enterprises.should == [e2]
      end
    end

    describe "finding exchanges of an order cycle that an admin can manage" do
      let(:oc) { create(:simple_order_cycle) }
      let!(:ex) { create(:exchange, order_cycle: oc, sender: e1, receiver: e2) }

      before do
        permissions.stub(:managed_enterprises) { [] }
        permissions.stub(:related_enterprises_with) { [] }
      end

      it "returns exchanges involving enterprises managed by the user" do
        permissions.stub(:managed_enterprises) { [e1, e2] }
        permissions.order_cycle_exchanges(oc).should == [ex]
      end

      it "returns exchanges involving enterprises with E2E permission" do
        permissions.stub(:related_enterprises_with) { [e1, e2] }
        permissions.order_cycle_exchanges(oc).should == [ex]
      end

      it "does not return exchanges involving only the sender" do
        permissions.stub(:managed_enterprises) { [e1] }
        permissions.order_cycle_exchanges(oc).should == []
      end

      it "does not return exchanges involving only the receiver" do
        permissions.stub(:managed_enterprises) { [e2] }
        permissions.order_cycle_exchanges(oc).should == []
      end
    end

    ########################################

    describe "finding related enterprises with a particular permission" do
      let!(:er) { create(:enterprise_relationship, parent: e1, child: e2, permissions_list: [permission]) }

      it "returns the enterprises" do
        permissions.stub(:managed_enterprises) { e2 }
        permissions.send(:related_enterprises_with, permission).should == [e1]
      end

      it "returns an empty array when there are none" do
        permissions.stub(:managed_enterprises) { e1 }
        permissions.send(:related_enterprises_with, permission).should == []
      end
    end
  end
end
