require 'open_food_network/feature_toggle'

OpenFoodNetwork::FeatureToggle.enable(:customer_balance) do |user|
  true
end

OpenFoodNetwork::FeatureToggle.enable(:unit_price) do
  Rails.env.development?
end
