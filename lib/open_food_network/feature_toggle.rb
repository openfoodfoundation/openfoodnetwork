module OpenFoodNetwork
  class FeatureToggle
    def self.enabled?(feature_name)
      true?(env_variable_value(feature_name))
    end

    private

    def self.env_variable_value(feature_name)
      ENV.fetch(env_variable_name(feature_name), nil)
    end

    def self.env_variable_name(feature_name)
      "OFN_FEATURE_#{feature_name.to_s.upcase}"
    end

    def self.true?(value)
      value.to_s.casecmp("true").zero?
    end
  end
end
