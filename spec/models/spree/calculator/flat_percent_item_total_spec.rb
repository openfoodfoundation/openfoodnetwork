require 'spec_helper'

describe Spree::Calculator::FlatPercentItemTotal do
  let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new }
  let(:line_item) { instance_double(Spree::LineItem, amount: 10) }

  before { allow(calculator).to receive_messages :preferred_flat_percent => 10 }

  it "should compute amount correctly for a single line item" do
    expect(calculator.compute(line_item)).to eq(1.0)
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_flat_percent]
  end
end
