require 'spec_helper'

describe Spree::Calculator::FlexiRate do
  let(:calculator_first) { Spree::Calculator::FlexiRate.new(preferred_first_item: 2, preferred_additional_item: 1, preferred_max_items: 3.0) }
  let(:calculator_second) { Spree::Calculator::FlexiRate.new(preferred_first_item: 2, preferred_additional_item: 1, preferred_max_items: 5.0) }

  let(:line_item) { instance_double(Spree::LineItem, amount: 10, quantity: 4) }

  describe "computing for a single line item" do
    it "returns the first item rate when quantity is above max" do
      expect(calculator_first.compute(line_item).round(2)).to eq(4.0)
    end

    it "returns the first item rate when quantity is below max" do
      expect(calculator_second.compute(line_item).round(2)).to eq(5.0)
    end
  end

  it "allows creation of new object with all the attributes" do
    Spree::Calculator::FlexiRate.new(preferred_first_item: 1, preferred_additional_item: 1, preferred_max_items: 1)
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_first_item, :preferred_additional_item]
  end
end
