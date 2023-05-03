# frozen_string_literal: true

require 'spec_helper'

describe OpenFoodNetwork::FeatureToggle do
  subject(:feature_toggle) { OpenFoodNetwork::FeatureToggle }

  context 'when users are not specified' do
    it "returns false when feature is undefined" do
      expect(feature_toggle.enabled?(:foo)).to be false
    end

    it "uses Flipper configuration" do
      Flipper.enable(:foo)
      expect(feature_toggle.enabled?(:foo)).to be true
    end
  end

  describe ".setup!" do
    it "created all current features at boot time" do
      expect(Flipper.features.count)
        .to eq feature_toggle::CURRENT_FEATURES.count
    end

    it "adds any missing features" do
      pending "We don't have features to test with at the moment." if Flipper.features.empty?

      feature = Flipper.features.first
      feature.remove

      expect { feature_toggle.setup! }
        .to change { Flipper.features }.by([feature])
    end
  end
end
