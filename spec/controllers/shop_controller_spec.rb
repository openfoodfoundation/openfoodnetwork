require 'spec_helper'

describe ShopController do
  it "should select an order cycle when only one order cycle is open" do
    d = create(:distributor_enterprise)
    oc1 = create(:order_cycle, distributors: [d])
    controller.stub(:current_distributor).and_return d
    spree_get :index
    controller.current_order_cycle.should == oc1
  end

  it "should not set an order cycle when multiple order cycles are open" do
    d = create(:distributor_enterprise)
    oc1 = create(:order_cycle, distributors: [d])
    oc2 = create(:order_cycle, distributors: [d])
    controller.stub(:current_distributor).and_return d
    spree_get :index
    controller.current_order_cycle.should == nil
  end

  it "should create/load an order when loading show"
end
