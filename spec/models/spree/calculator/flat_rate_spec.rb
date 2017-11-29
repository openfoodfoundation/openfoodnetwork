require 'spec_helper'

describe Spree::Calculator::FlatRate do
  let(:calculator) { Spree::Calculator::FlatRate.new }

  before { calculator.stub :preferred_amount => 10 }

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_amount]
  end
end
