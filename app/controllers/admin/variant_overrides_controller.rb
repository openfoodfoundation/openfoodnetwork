require 'open_food_network/spree_api_key_loader'

module Admin
  class VariantOverridesController < ResourceController
    include OpenFoodNetwork::SpreeApiKeyLoader
    include EnterprisesHelper

    before_filter :load_data
    before_filter :load_collection, only: [:bulk_update]
    before_filter :load_spree_api_key, only: :index

    def index; end

    def bulk_update
      # Ensure we're authorised to update all variant overrides
      @vo_set.collection.each { |vo| authorize! :update, vo }

      if @vo_set.save
        # Return saved VOs with IDs
        render json: @vo_set.collection, each_serializer: Api::Admin::VariantOverrideSerializer
      else
        if @vo_set.errors.present?
          render json: { errors: @vo_set.errors }, status: :bad_request
        else
          render nothing: true, status: :internal_server_error
        end
      end
    end

    def bulk_reset
      # Ensure we're authorised to update all variant overrides.
      @collection.each { |vo| authorize! :bulk_reset, vo }
      @collection.each(&:reset_stock!)

      if collection_errors.present?
        render json: { errors: collection_errors }, status: :bad_request
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
      @import_dates = inventory_import_dates.uniq.to_json
    end

    def inventory_import_dates
      import_dates = VariantOverride.
        distinct_import_dates.
        for_hubs(editable_enterprises.collect(&:id))

      options = [{ id: '0', name: 'All' }]
      import_dates.collect(&:import_date).map { |i| options.push(id: i.to_date, name: i.to_date.to_formatted_s(:long)) }

      options
    end

    def load_collection
      collection_hash = Hash[variant_overrides_params.each_with_index.map { |vo, i| [i, vo] }]
      @vo_set = VariantOverrideSet.new @variant_overrides, collection_attributes: collection_hash
    end

    def collection
      @variant_overrides = VariantOverride.
        includes(:variant).
        for_hubs(params[:hub_id] || @hubs).
        references(:variant)
      @variant_overrides.select { |vo| vo.variant.present? }
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

    def variant_overrides_params
      params.require(:variant_overrides).map do |variant_override|
        variant_override.permit(
          :id, :variant_id, :hub_id,
          :price, :count_on_hand, :sku, :on_demand,
          :default_stock, :resettable
        )
      end
    end
  end
end
