require 'open_food_network/feature_toggle'

module OpenFoodNetwork
  describe FeatureToggle do
    it "returns true when feature is on" do
      stub_foo("true")
      expect(FeatureToggle.enabled?(:foo)).to be true
    end

    it "returns false when feature is off" do
      stub_foo("false")
      expect(FeatureToggle.enabled?(:foo)).to be false
    end

    it "returns false when feature is unspecified" do
      stub_foo("maybe")
      expect(FeatureToggle.enabled?(:foo)).to be false
    end

    it "returns false when feature is undefined" do
      expect(FeatureToggle.enabled?(:foo)).to be false
    end

    def stub_foo(value)
      allow(ENV).to receive(:fetch).with("OFN_FEATURE_FOO", nil).and_return(value)
    end
  end
end
