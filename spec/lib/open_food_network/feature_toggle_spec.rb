require 'open_food_network/feature_toggle'

module OpenFoodNetwork
  describe FeatureToggle do
    it "returns true when feature is on" do
      allow(FeatureToggle).to receive(:features).and_return({foo: true})
      expect(FeatureToggle.enabled?(:foo)).to be true
    end

    it "returns false when feature is off" do
      allow(FeatureToggle).to receive(:features).and_return({foo: false})
      expect(FeatureToggle.enabled?(:foo)).to be false
    end

    it "returns false when feature is undefined" do
      allow(FeatureToggle).to receive(:features).and_return({})
      expect(FeatureToggle.enabled?(:foo)).to be false
    end
  end
end
