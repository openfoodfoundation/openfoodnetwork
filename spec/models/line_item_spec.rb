require 'spec_helper'

module Spree
  describe LineItem do
    it "computes shipping cost for its product" do
      distributor = double(:distributor)
      order = double(:order, :distributor => distributor)

      product = double(:product)
      product.should_receive(:shipping_cost_for_distributor).with(distributor).and_return(10)

      subject.stub(:order).and_return(order)
      subject.stub(:product).and_return(product)

      subject.itemwise_shipping_cost.should == 10
    end
  end
end
