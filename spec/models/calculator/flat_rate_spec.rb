# frozen_string_literal: true

require 'spec_helper'

describe Calculator::FlatRate do
  let(:calculator) { Calculator::FlatRate.new }

  before { allow(calculator).to receive_messages preferred_amount: 10 }

  it { is_expected.to validate_numericality_of(:preferred_amount) }
end
