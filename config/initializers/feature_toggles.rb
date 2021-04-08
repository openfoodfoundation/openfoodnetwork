require 'open_food_network/feature_toggle'

beta_testers = ENV['BETA_TESTERS']&.split(/[\s,]+/) || []

OpenFoodNetwork::FeatureToggle.enable(:customer_balance) do |user|
  if beta_testers == ['all']
    true
  else
    beta_testers.include?(user.email)
  end
end

OpenFoodNetwork::FeatureToggle.enable(:unit_price) do
  Rails.env.development?
end
