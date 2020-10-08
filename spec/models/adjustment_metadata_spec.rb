require 'spec_helper'

describe AdjustmentMetadata do
  it "is valid when built from factory" do
    adjustment_metadata = build(:adjustment_metadata)
    expect(adjustment_metadata).to be_valid
  end
end
