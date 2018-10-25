class RevokeVariantOverrideswithoutPermissions < ActiveRecord::Migration
  def up
    # This process was executed when the permission_revoked_at colum was created (see AddPermissionRevokedAtToVariantOverrides)
    #   It needs to be repeated due to #2739
    variant_override_hubs = Enterprise.where(id: VariantOverride.select(:hub_id).uniq)

    variant_override_hubs.find_each do |hub|
      permitting_producer_ids = hub.relationships_as_child
        .with_permission(:create_variant_overrides).pluck(:parent_id)

      variant_overrides_with_revoked_permissions = VariantOverride.for_hubs(hub)
        .joins(variant: :product).where("spree_products.supplier_id NOT IN (?)", permitting_producer_ids)

      variant_overrides_with_revoked_permissions.update_all(permission_revoked_at: Time.now)
    end
  end
end
