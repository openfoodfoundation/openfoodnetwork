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


    def bulk_update
      collection_hash = Hash[params[:variant_overrides].each_with_index.map { |vo, i| [i, vo] }]
      vo_set = VariantOverrideSet.new collection_attributes: collection_hash

      # Ensure we're authorised to update all variant overrides
      vo_set.collection.each { |vo| authorize! :update, vo }

      if vo_set.save
        # Return saved VOs with IDs
        render json: vo_set.collection, each_serializer: Api::Admin::VariantOverrideSerializer
      else
        if vo_set.errors.present?
          render json: { errors: vo_set.errors }, status: 400
        else
          render nothing: true, status: 500
        end
      end
    end


    def collection
    end
  end
end
