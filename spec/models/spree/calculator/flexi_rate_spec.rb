require 'spec_helper'

describe Spree::Calculator::FlexiRate do
  let(:calculator) { Spree::Calculator::FlexiRate.new }
  let(:line_item) { instance_double(Spree::LineItem, amount: 10, quantity: 4) }

  describe "computing for a single line item" do
    it "returns the first item rate" do
      calculator.stub preferred_first_item: 1.0
      calculator.compute(line_item).round(2).should == 1.0
    end
  end

  it "allows creation of new object with all the attributes" do
    Spree::Calculator::FlexiRate.new(preferred_first_item: 1, preferred_additional_item: 1, preferred_max_items: 1)
  end
end
