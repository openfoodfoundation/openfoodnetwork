# frozen_string_literal: true

require 'spec_helper'

describe AdjustmentMetadata do
  it { is_expected.to belong_to(:adjustment).required }
  it { is_expected.to belong_to(:enterprise).required }

  it "is valid when built from factory" do
    adjustment_metadata = build(:adjustment_metadata)
    expect(adjustment_metadata).to be_valid
  end
end
