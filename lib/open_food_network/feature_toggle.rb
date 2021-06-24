# frozen_string_literal: true

module OpenFoodNetwork
  # Feature toggles are configured via Flipper.
  #
  # We define features in the initializer and then it can be customised via the
  # web interface on each server.
  #
  # - config/initializers/flipper.rb
  # - http://localhost:3000/admin/feature-toggle/features
  #
  module FeatureToggle
    def self.enabled?(feature_name, user = nil)
      Flipper.enabled?(feature_name, user)
    end
  end
end
