require 'spec_helper'

describe OpenFoodWeb::Calculator::Itemwise do
  it "computes the shipping cost for each line item in an order" do
    line_item = double(:line_item)
    line_item.should_receive(:itemwise_shipping_cost).exactly(3).times.and_return(10)

    order = double(:order)
    order.stub(:line_items).and_return([line_item]*3)

    subject.compute(order).should == 30
  end

  it "returns zero for an order with no items" do
    order = double(:order)
    order.stub(:line_items).and_return([])

    subject.compute(order).should == 0
  end
end
