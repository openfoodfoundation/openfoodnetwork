module OpenFoodWeb
  module FeatureToggleHelper
    def set_feature_toggle(feature, status)
      features = OpenFoodWeb::FeatureToggle.features
      features[feature] = status
      OpenFoodWeb::FeatureToggle.stub(:features) { features }
    end
  end
end
