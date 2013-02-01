require 'spec_helper'

describe OrderCyclesHelper do
  subject do
    obj = Object.new
    obj.extend(OrderCyclesHelper)
  end

  describe "generating local/remote classes for order cycle selection" do
    it "returns blank when no distributor or order cycle is selected" do
      subject.order_cycle_local_remote_class(nil, double(:order_cycle)).should == ''
      subject.order_cycle_local_remote_class(double(:distributor), nil).should == ''
    end

    it "returns local when the order cycle includes the current distributor" do
      distributor = double(:enterprise)
      order_cycle = double(:order_cycle, distributors: [distributor])

      subject.order_cycle_local_remote_class(distributor, order_cycle).should == ' local'
    end

    it "returns remote when the order cycle does not include the current distributor" do
      distributor = double(:enterprise)
      order_cycle = double(:order_cycle, distributors: [])

      subject.order_cycle_local_remote_class(distributor, order_cycle).should == ' remote'
    end
  end
end
