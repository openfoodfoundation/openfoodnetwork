# frozen_string_literal: true

module OpenFoodNetwork
  module SpreeApiKeyLoader
    def load_spree_api_key
      if spree_current_user
        if spree_current_user.spree_api_key.blank?
          spree_current_user.generate_api_key
          spree_current_user.save
        end

        @spree_api_key = spree_current_user.spree_api_key
      else
        @spree_api_key = nil
      end
    end
  end
end
