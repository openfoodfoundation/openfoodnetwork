module OpenFoodNetwork
  class FeatureToggle
    def self.enabled? feature
      features[feature]
    end

    private

    def self.features
      {order_cycles: true}
    end
  end
end
