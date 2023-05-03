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
end
