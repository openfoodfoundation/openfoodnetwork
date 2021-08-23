# frozen_string_literal: true

module OpenFoodNetwork
  module FeatureToggleHelper
    def set_feature_toggle(feature, status)
      features = OpenFoodNetwork::FeatureToggle.features
      features[feature] = status
      allow(OpenFoodNetwork::FeatureToggle).to receive(:features) { features }
    end
  end
end
