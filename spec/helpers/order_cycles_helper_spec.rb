require 'spec_helper'

describe OrderCyclesHelper do
  describe "generating local/remote classes for order cycle selection" do
    it "returns blank when no distributor or order cycle is selected" do
      helper.order_cycle_local_remote_class(nil, double(:order_cycle)).should == ''
      helper.order_cycle_local_remote_class(double(:distributor), nil).should == ''
    end

    it "returns local when the order cycle includes the current distributor" do
      distributor = double(:enterprise)
      order_cycle = double(:order_cycle, distributors: [distributor])

      helper.order_cycle_local_remote_class(distributor, order_cycle).should == ' local'
    end

    it "returns remote when the order cycle does not include the current distributor" do
      distributor = double(:enterprise)
      order_cycle = double(:order_cycle, distributors: [])

      helper.order_cycle_local_remote_class(distributor, order_cycle).should == ' remote'
    end
  end

  it "gives me the pickup time for an order_cycle" do
      d = create(:distributor_enterprise, name: 'Green Grass')
      oc1 = create(:simple_order_cycle, name: 'oc 1', distributors: [d])
      exchange = Exchange.find(oc1.exchanges.to_enterprises(d).outgoing.first.id) 
      exchange.update_attribute :pickup_time, "turtles" 

      helper.stub!(:current_order_cycle).and_return oc1
      helper.stub!(:current_distributor).and_return d
      helper.pickup_time.should == "turtles"
  end
end
