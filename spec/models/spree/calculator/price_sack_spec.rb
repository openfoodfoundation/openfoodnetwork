require 'spec_helper'

describe Spree::Calculator::PriceSack do
  let(:calculator) do
    calculator = Spree::Calculator::PriceSack.new
    calculator.preferred_minimal_amount = 5
    calculator.preferred_normal_amount = 10
    calculator.preferred_discount_amount = 1
    calculator
  end

  let(:line_item) { build(:line_item, price: 1, quantity: 2) }

  it "computes with a line item object" do
    calculator.compute(line_item)
  end
end
