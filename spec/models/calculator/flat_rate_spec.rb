# frozen_string_literal: true

require 'spec_helper'

describe Calculator::FlatRate do
  let(:calculator) { Calculator::FlatRate.new }

  before { allow(calculator).to receive_messages preferred_amount: 10 }

  it do
    should validate_numericality_of(:preferred_amount).
      with_message("Invalid input. Please use only numbers. For example: 10, 5.5, -20")
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_amount]
    it_behaves_like "a Spree Calculator model using the LocalizedNumber module", [:preferred_amount]
  end
end
