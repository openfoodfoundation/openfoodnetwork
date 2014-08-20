module OpenFoodNetwork
  module SpreeApiKeyLoader
    def load_spree_api_key
      current_user.generate_spree_api_key! unless spree_current_user.spree_api_key
      @spree_api_key = spree_current_user.spree_api_key
    end
  end
end