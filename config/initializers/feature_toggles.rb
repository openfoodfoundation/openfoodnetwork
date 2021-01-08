require 'open_food_network/feature_toggle'

beta_testers = ENV['BETA_TESTERS']&.split(/[\s,]+/)

OpenFoodNetwork::FeatureToggle.enable(:customer_balance, beta_testers)
