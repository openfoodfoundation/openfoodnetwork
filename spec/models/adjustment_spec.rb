module Spree
  describe Adjustment do
    it "has metadata" do
      adjustment = create(:adjustment, metadata: create(:adjustment_metadata))
      adjustment.metadata.should be
    end
  end
end
