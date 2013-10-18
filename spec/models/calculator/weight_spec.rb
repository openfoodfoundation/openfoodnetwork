require 'spec_helper'

describe OpenFoodNetwork::Calculator::Weight do
  it "computes shipping cost for an order by total weight" do
    variant_1 = double(:variant, :weight => 10)
    variant_2 = double(:variant, :weight => 20)
    variant_3 = double(:variant, :weight => nil)

    line_item_1 = double(:line_item, :variant => variant_1, :quantity => 1)
    line_item_2 = double(:line_item, :variant => variant_2, :quantity => 3)
    line_item_3 = double(:line_item, :variant => variant_3, :quantity => 5)

    order = double(:order, :line_items => [line_item_1, line_item_2, line_item_3])

    subject.set_preference(:per_kg, 10)
    subject.compute(order).should == (10*1 + 20*3) * 10
  end

  it "computes shipping cost for a line item" do
    variant = double(:variant, :weight => 10)

    line_item = double(:line_item, :variant => variant, :quantity => 2)

    subject.set_preference(:per_kg, 10)
    subject.compute(line_item).should == 10*2 * 10
  end
end
