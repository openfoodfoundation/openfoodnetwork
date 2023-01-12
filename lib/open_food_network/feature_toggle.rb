# frozen_string_literal: true

module OpenFoodNetwork
  # Feature toggles are configured via Flipper.
  #
  # - config/initializers/flipper.rb
  # - http://localhost:3000/admin/feature-toggle/features
  #
  module FeatureToggle
    def self.enabled?(feature_name, user = nil)
      feature = Flipper.feature(feature_name)
      feature.add unless feature.exist?
      feature.enabled?(user)
    end

    def self.disabled?(feature_name, user = nil)
      !enabled?(feature_name, user)
    end
  end
end
