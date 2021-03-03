require 'open_food_network/feature_toggle'

beta_testers = ENV['BETA_TESTERS']&.split(/[\s,]+/) || []

OpenFoodNetwork::FeatureToggle.enable(:customer_balance) do |user|
  if beta_testers == ['all']
    true
  else
    beta_testers.include?(user.email)
  end
end


unit_price_beta_testers = ENV['BETA_TESTERS_FOR_UNIT_PRICE']&.split(/[\s,]+/) || []
OpenFoodNetwork::FeatureToggle.enable(:unit_price) do |user|
  if ['development', 'staging'].include?(ENV['RAILS_ENV'])
    true
  else
    unit_price_beta_testers.include?(user.email)
  end
end
