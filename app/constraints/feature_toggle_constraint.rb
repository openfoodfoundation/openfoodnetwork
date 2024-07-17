# frozen_string_literal: true

require "open_food_network/feature_toggle"

class FeatureToggleConstraint
  def initialize(feature_name, negate: false)
    @feature = feature_name
    @negate = negate
  end

  def matches?(request)
    enabled?(request) ^ @negate
  end

  def enabled?(request)
    user = current_user(request)
    enabled = OpenFoodNetwork::FeatureToggle.enabled?(@feature, user)
    Rails.logger.info "FeatureToggleConstraint #{@feature} enabled: #{enabled.to_s}; for user: #{user&.id.to_s}; path: #{request.path}"
    enabled
  end

  def current_user(request)
    request.env['warden']&.user
  end
end
