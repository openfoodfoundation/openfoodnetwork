require 'spec_helper'

describe Calculator::FlatRate do
  let(:calculator) { Calculator::FlatRate.new }

  before { allow(calculator).to receive_messages preferred_amount: 10 }

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_amount]
  end
end
