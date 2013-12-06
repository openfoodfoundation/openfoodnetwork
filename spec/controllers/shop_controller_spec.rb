require 'spec_helper'

describe ShopController do
  let(:d) { create(:distributor_enterprise) }
  before do
    controller.stub(:current_distributor).and_return d
  end

  describe "Selecting order cycles" do
    it "should select an order cycle when only one order cycle is open" do
      oc1 = create(:order_cycle, distributors: [d])
      spree_get :show
      controller.current_order_cycle.should == oc1
    end

    it "should not set an order cycle when multiple order cycles are open" do
      oc1 = create(:order_cycle, distributors: [d])
      oc2 = create(:order_cycle, distributors: [d])
      spree_get :show
      controller.current_order_cycle.should == nil
    end
  end

  describe "returning products" do
    let(:product) { create(:product) }
    let(:order_cycle) { create(:order_cycle, distributors: [d]) }
    before do
      Spree::Product.stub(:all).and_return([product])
    end

    it "returns products via json" do
      controller.stub(:current_order_cycle).and_return order_cycle
      xhr :get, :products
      response.should be_success
      response.body.should_not be_empty
    end

    it "does not return products if no order_cycle is selected" do
      xhr :get, :products
      response.status.should == 404
      response.body.should be_empty
    end
  end
end
