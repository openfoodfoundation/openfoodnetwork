describe AdjustmentMetadata do
  it "is valid when build from factory" do
    adjustment = create(:adjustment)
    expect(adjustment).to be_valid
  end
end
