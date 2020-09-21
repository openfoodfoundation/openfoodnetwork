require 'spec_helper'

describe AdjustmentMetadata do
  it "is valid when built from factory" do
    adjustment = build(:adjustment)
    expect(adjustment).to be_valid
  end
end
