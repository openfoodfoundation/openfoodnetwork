module OpenFoodNetwork
  class FeatureToggle
    def self.enabled? feature
      !!features.with_indifferent_access[feature]
    end

    private

    def self.features
      {connect_learn_homepage: false}
    end
  end
end
