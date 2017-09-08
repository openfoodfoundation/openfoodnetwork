require 'spec_helper'

 describe Spree::Calculator::FlatPercentItemTotal do
  let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new }
  let(:line_item) { instance_double(Spree::LineItem, amount: 10) }

  before { calculator.stub :preferred_flat_percent => 10 }

  it "should compute amount correctly for a single line item" do
    calculator.compute(line_item).should == 1.0
  end
end
