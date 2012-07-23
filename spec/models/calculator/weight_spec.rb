require 'spec_helper'

describe OpenFoodWeb::Calculator::Weight do
  it "computes shipping cost for an order by total weight" do
    variant_1 = double(:variant, :weight => 10)
    variant_2 = double(:variant, :weight => 20)

    line_item_1 = double(:line_item, :variant => variant_1, :quantity => 1)
    line_item_2 = double(:line_item, :variant => variant_2, :quantity => 3)

    order = double(:order, :line_items => [line_item_1, line_item_2])

    subject.set_preference(:per_kg, 10)
    subject.compute(order).should == (10*1 + 20*3) * 10
  end
end
