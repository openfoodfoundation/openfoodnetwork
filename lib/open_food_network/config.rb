
module OpenFoodNetwork

  class Spree::OpenFoodNetworkConfiguration < Spree::Preferences::Configuration
    preference :country_code, :string, :default => "au"
  end

  OpenFoodNetwork::Config = Spree::OpenFoodNetworkConfiguration.new
end
