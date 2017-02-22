require 'open_food_network/feature_toggle'

module OpenFoodNetwork
  describe FeatureToggle do
    it "returns true when feature is on" do
      FeatureToggle.stub(:features).and_return({foo: true})
      FeatureToggle.enabled?(:foo).should be true
    end

    it "returns false when feature is off" do
      FeatureToggle.stub(:features).and_return({foo: false})
      FeatureToggle.enabled?(:foo).should be false
    end

    it "returns false when feature is undefined" do
      FeatureToggle.stub(:features).and_return({})
      FeatureToggle.enabled?(:foo).should be false
    end
  end
end
