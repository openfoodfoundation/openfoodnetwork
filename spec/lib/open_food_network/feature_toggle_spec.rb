# frozen_string_literal: true

require 'spec_helper'

module OpenFoodNetwork
  describe FeatureToggle do
    context 'when users are not specified' do
      it "returns false when feature is undefined" do
        expect(FeatureToggle.enabled?(:foo)).to be false
      end

      it "uses Flipper configuration" do
        Flipper.enable(:foo)
        expect(FeatureToggle.enabled?(:foo)).to be true
      end
    end
  end
end
