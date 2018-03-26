require 'spec_helper'

describe Spree::Calculator::FlexiRate do
  let(:calculator) { Spree::Calculator::FlexiRate.new(preferred_first_item: 2, preferred_additional_item: 1) }
  let(:line_item) { instance_double(Spree::LineItem, amount: 10, quantity: 4) }

  describe "computing for a single line item" do
    it "returns the first item rate when above max" do
      calculator.stub preferred_max_items: 3.0
      calculator.compute(line_item).round(2).should == 4.0
    end

    it "returns the first item rate when below max" do
      calculator.stub preferred_max_items: 5.0
      calculator.compute(line_item).round(2).should == 5.0
    end
  end

  it "allows creation of new object with all the attributes" do
    Spree::Calculator::FlexiRate.new(preferred_first_item: 1, preferred_additional_item: 1, preferred_max_items: 1)
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_first_item, :preferred_additional_item]
  end
end
