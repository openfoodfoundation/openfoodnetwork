# frozen_string_literal: true

require 'spec_helper'

describe Calculator::FlatPercentPerItem do
  let(:calculator) { Calculator::FlatPercentPerItem.new preferred_flat_percent: 20 }

  it { is_expected.to validate_numericality_of(:preferred_flat_percent) }

  it "calculates for a simple line item" do
    line_item = Spree::LineItem.new price: 50, quantity: 2
    expect(calculator.compute(line_item)).to eq 20
  end

  it "rounds fractional cents before summing" do
    line_item = Spree::LineItem.new price: 0.86, quantity: 8
    expect(calculator.compute(line_item)).to eq 1.36
  end
end
