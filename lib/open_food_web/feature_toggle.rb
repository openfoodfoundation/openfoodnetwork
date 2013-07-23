module OpenFoodWeb
  class FeatureToggle
    def self.enabled? feature
      features[feature]
    end


    private

    def self.features
      {eaterprises: true,
       local_organics: false,
       order_cycles: false,
       enterprises_distributor_info_rich_text: false}
    end
  end
end
