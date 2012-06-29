require 'spec_helper'

module Spree
  describe LineItem do
    it "computes shipping cost for its product" do
      # Create a shipping method with flat rate of 10
      shipping_method = create(:shipping_method)
      shipping_method.calculator.set_preference :amount, 10

      product = double(:product)
      product.should_receive(:shipping_method_for_distributor).and_return(shipping_method)

      order = double(:order, :distributor => nil)

      subject.stub(:product).and_return(product)
      subject.stub(:order).and_return(order)

      subject.itemwise_shipping_cost.should == 10
    end
  end
end
