module OpenFoodNetwork
  class FeatureToggle
    def self.enabled? feature
      features[feature]
    end

    private

    def self.features
      {eaterprises: true,
       local_organics: false,
       order_cycles: true,
       multi_cart: false,
       enterprises_distributor_info_rich_text: true}
    end
  end
end
