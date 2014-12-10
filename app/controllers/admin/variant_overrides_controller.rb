require 'open_food_network/spree_api_key_loader'

module Admin
  class VariantOverridesController < ResourceController
    include OpenFoodNetwork::SpreeApiKeyLoader
    include OrderCyclesHelper
    before_filter :load_spree_api_key, only: :index

    def index
      @hubs = order_cycle_hub_enterprises(without_validation: true)
      @producers = order_cycle_producer_enterprises
      @hub_permissions = OpenFoodNetwork::Permissions.new(spree_current_user).
        order_cycle_enterprises_per_hub
      @variant_overrides = VariantOverride.for_hubs(@hubs)
    end
  end
end
