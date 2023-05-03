# frozen_string_literal: true

require 'spec_helper'

describe Calculator::PerItem do
  let(:calculator) { Calculator::PerItem.new(preferred_amount: 10) }
  let(:shipping_calculable) { double(:calculable) }
  let(:line_item) { build_stubbed(:line_item, quantity: 5) }

  it { is_expected.to validate_numericality_of(:preferred_amount) }

  it "correctly calculates on a single line item object" do
    allow(calculator).to receive_messages(calculable: shipping_calculable)
    expect(calculator.compute(line_item).to_f).to eq(50) # 5 x 10
  end
end
