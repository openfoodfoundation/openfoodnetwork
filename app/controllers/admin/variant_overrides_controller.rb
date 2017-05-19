require 'open_food_network/spree_api_key_loader'

module Admin
  class VariantOverridesController < ResourceController
    include OpenFoodNetwork::SpreeApiKeyLoader

    prepend_before_filter :load_data
    before_filter :load_collection, only: [:bulk_update]
    before_filter :load_spree_api_key, only: :index


    def index
    end

    def bulk_update
      # Ensure we're authorised to update all variant overrides
      @vo_set.collection.each { |vo| authorize! :update, vo }

      if @vo_set.save
        # Return saved VOs with IDs
        render json: @vo_set.collection, each_serializer: Api::Admin::VariantOverrideSerializer
      else
        if @vo_set.errors.present?
          render json: { errors: @vo_set.errors }, status: 400
        else
          render nothing: true, status: 500
        end
      end
    end

    def bulk_reset
      # Ensure we're authorised to update all variant overrides.
      @collection.each { |vo| authorize! :bulk_reset, vo }
      @collection.each(&:reset_stock!)

      if collection_errors.present?
        render json: { errors: collection_errors }, status: 400
      else
        render json: @collection, each_serializer: Api::Admin::VariantOverrideSerializer
      end
    end


    private

    def load_data
      @hubs = OpenFoodNetwork::Permissions.new(spree_current_user).
        variant_override_hubs.by_name

      # Used in JS to look up the name of the producer of each product
      @producers = OpenFoodNetwork::Permissions.new(spree_current_user).
        variant_override_producers

      @hub_permissions = OpenFoodNetwork::Permissions.new(spree_current_user).
        variant_override_enterprises_per_hub

      @inventory_items = InventoryItem.where(enterprise_id: @hubs)
    end

    def load_collection
      collection_hash = Hash[params[:variant_overrides].each_with_index.map { |vo, i| [i, vo] }]
      @vo_set = VariantOverrideSet.new @variant_overrides, collection_attributes: collection_hash
    end

    def collection
      @variant_overrides = VariantOverride.for_hubs(params[:hub_id] || @hubs)
    end

    def collection_actions
      [:index, :bulk_update, :bulk_reset]
    end

    # This has been pulled from ModelSet as it is useful for compiling a list of errors on any generic collection (not necessarily a ModelSet)
    # Could be pulled down into a lower level controller if it is useful in other high level controllers
    def collection_errors
      errors = ActiveModel::Errors.new self
      full_messages = @collection.map { |element| element.errors.full_messages }.flatten
      full_messages.each { |fm| errors.add(:base, fm) }
      errors
    end
  end
end
