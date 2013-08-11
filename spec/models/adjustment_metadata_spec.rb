describe AdjustmentMetadata do
  it "is valid when build from factory" do
    adjustment = create(:adjustment)
    adjustment.should be_valid
  end
end
