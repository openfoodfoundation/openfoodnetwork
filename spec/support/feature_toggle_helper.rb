module OpenFoodNetwork
  module FeatureToggleHelper
    def set_feature_toggle(feature, status)
      features = OpenFoodNetwork::FeatureToggle.features
      features[feature] = status
      OpenFoodNetwork::FeatureToggle.stub(:features) { features }
    end
  end
end
