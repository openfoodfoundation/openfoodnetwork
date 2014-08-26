require 'open_food_network/permissions'

module OpenFoodNetwork
  describe Permissions do
    let(:user) { double(:user) }
    let(:permissions) { Permissions.new(user) }
    let(:permission) { 'one' }
    let(:e1) { create(:enterprise) }
    let(:e2) { create(:enterprise) }

    describe "finding producers that can be added to an order cycle" do
      let(:producer1) { double(:enterprise1, name: 'A') }
      let(:producer2) { double(:enterprise2, name: 'B') }
      let(:producer3) { double(:enterprise3, name: 'C') }

      it "returns managed producers and related+permitted enterprises, sorted by name" do
        permissions.stub(:managed_producers) { [producer1, producer3] }
        permissions.stub(:related_producers_with) { [producer2] }

        permissions.order_cycle_producers.should == [producer1, producer2, producer3]
      end
    end

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

    describe "finding related producers with a particular permission" do
      it "returns permitted related enterprises that are also producers" do
        permissions.stub_chain(:related_enterprises_with, :is_primary_producer) { [e1] }
        permissions.send(:related_producers_with, permission).should == [e1]
      end
    end
  end
end
