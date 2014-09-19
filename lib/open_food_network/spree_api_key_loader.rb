module OpenFoodNetwork
  module SpreeApiKeyLoader
    def load_spree_api_key
      if spree_current_user
        spree_current_user.generate_spree_api_key! unless spree_current_user.spree_api_key
        @spree_api_key = spree_current_user.spree_api_key
      else
        @spree_api_key = nil
      end
    end
  end
end
