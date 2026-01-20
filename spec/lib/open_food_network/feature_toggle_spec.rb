# frozen_string_literal: true

RSpec.describe OpenFoodNetwork::FeatureToggle do
  subject(:feature_toggle) { OpenFoodNetwork::FeatureToggle }

  describe ".enabled?" do
    it "returns false when feature is undefined" do
      expect(feature_toggle.enabled?(:foo)).to be false
    end

    it "uses Flipper configuration" do
      Flipper.enable(:foo)
      expect(feature_toggle.enabled?(:foo)).to be true
    end

    it "can be activated per enterprise" do
      enterprise = Enterprise.new(id: 5)

      Flipper.enable(:foo, enterprise)

      expect(feature_toggle.enabled?(:foo)).to eq false
      expect(feature_toggle.enabled?(:foo, enterprise)).to eq true
    end

    it "returns true for an enabled user amongst other actors" do
      user = Spree::User.new(id: 4)
      enterprise = Enterprise.new(id: 5)

      Flipper.enable(:foo, user)

      expect(feature_toggle.enabled?(:foo, user, enterprise)).to eq true
      expect(feature_toggle.enabled?(:foo, enterprise, user)).to eq true
    end
  end

  describe ".disabled?" do
    it "returns true if the feature is disabled for all actors" do
      user = Spree::User.new(id: 4)
      enterprise = Enterprise.new(id: 5)

      expect(feature_toggle.disabled?(:foo, user, enterprise)).to eq true
    end
  end

  describe ".setup!" do
    it "created all current features at boot time" do
      expect(Flipper.features.map(&:name))
        .to match_array feature_toggle::CURRENT_FEATURES.keys
    end

    it "adds any missing features" do
      pending "We don't have features to test with at the moment." if Flipper.features.empty?

      feature = Flipper.features.first
      feature.remove

      expect { feature_toggle.setup! }
        .to change { Flipper.features }.by([feature])
    end

    it "removes unknown features" do
      feature = Flipper.feature(:foo)
      feature.enable

      expect { feature_toggle.setup! }
        .to change { Flipper.features.count }.by(-1)
        .and change { feature.exist? }.to(false)
    end
  end
end
