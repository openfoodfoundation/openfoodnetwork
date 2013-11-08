require 'spec_helper'
require 'spree/api/testing_support/helpers'


describe Spree::CheckoutController do
  context "After completing an order" do
    it "should create a new empty order" do
      controller.current_order(true)
      controller.send(:after_complete)
      session[:order_id].should_not be_nil
    end

    it "should clear the current order cache" do
      order = controller.current_order(true)
      controller.send(:after_complete)
      controller.current_order.should_not == order
    end

    it "should set the new order's distributor to the same as the old order" do
      order = controller.current_order(true)
      distributor = create(:distributor_enterprise)
      order.set_distributor!(distributor)

      controller.send(:after_complete)

      controller.current_order.distributor.should == distributor
    end

    it "should set the new order's token to the same as the old order, and preserve the access token in the session" do
      order = controller.current_order(true)

      controller.send(:after_complete)

      controller.current_order.token.should == order.token
      session[:access_token].should == order.token
    end

  end
end
