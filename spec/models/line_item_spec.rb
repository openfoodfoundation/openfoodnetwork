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

      it "updates shipping method when order has not yet been placed" do
        %w(cart address delivery resumed).each do |state|
          order.stub(:state).and_return(state)
          line_item.should_receive(:set_itemwise_shipping_method)
          line_item.should_receive(:shipping_method_id_changed?).and_return(true)
          line_item.should_receive(:save!)
          line_item.itemwise_shipping_cost
        end
      end

      it "does not update shipping method when order has been placed" do
        %w(payment confirm complete cancelled returned awaiting_return).each do |state|
          order.stub(:state).and_return(state)
          line_item.should_receive(:set_itemwise_shipping_method).never
          line_item.should_receive(:save!).never
          line_item.itemwise_shipping_cost
        end
      end
    end
  end
end
