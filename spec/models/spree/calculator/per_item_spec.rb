require 'spec_helper'

describe Spree::Calculator::PerItem do
  let(:calculator) { Spree::Calculator::PerItem.new(preferred_amount: 10) }
  let(:shipping_calculable) { double(:calculable) }
  let(:line_item) { double(:line_item, quantity: 5, product: double(:product)) }

  it "correctly calculates on a single line item object" do
    allow(calculator).to receive_messages(calculable: shipping_calculable)
    expect(calculator.compute(line_item).to_f).to eq(50) # 5 x 10
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_amount]
  end
end
