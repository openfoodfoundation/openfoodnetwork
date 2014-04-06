
module OpenFoodNetwork

  class Spree::OpenFoodNetworkConfiguration < Spree::Preferences::Configuration
    preference :country, :string, :default => "Australia"
    preference :country_code, :string, :default => "au"
  end

  OpenFoodNetwork::Config = Spree::OpenFoodNetworkConfiguration.new
end
