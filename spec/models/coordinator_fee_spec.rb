# frozen_string_literal: true

require 'spec_helper'

describe CoordinatorFee do
  it { is_expected.to belong_to(:order_cycle).required }
  it { is_expected.to belong_to(:enterprise_fee).required }
end
