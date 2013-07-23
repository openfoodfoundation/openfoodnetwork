require 'spec_helper'

module Spree
  describe LineItem do
    describe "computing shipping cost for its product" do
      let(:shipping_method) do
        sm = create(:shipping_method)
        sm.calculator.set_preference :amount, 10
        sm
      end
      let(:order) { double(:order, :distributor => nil, :state => 'complete') }
      let(:line_item) do
        li = LineItem.new
        li.stub(:shipping_method).and_return(shipping_method)
        li.stub(:order).and_return(order)
        li
      end

      it "computes shipping cost for its product" do
        line_item.itemwise_shipping_cost.should == 10
      end
    end
  end
end
