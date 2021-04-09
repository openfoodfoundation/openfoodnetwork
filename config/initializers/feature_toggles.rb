require 'open_food_network/feature_toggle'

beta_testers = ENV['BETA_TESTERS']&.split(/[\s,]+/) || []

OpenFoodNetwork::FeatureToggle.enable(:customer_balance) do |user|
  !Rails.env.test?
end

OpenFoodNetwork::FeatureToggle.enable(:unit_price) do
  Rails.env.development?
end
