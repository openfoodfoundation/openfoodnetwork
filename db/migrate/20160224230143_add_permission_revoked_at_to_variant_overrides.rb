class AddPermissionRevokedAtToVariantOverrides < ActiveRecord::Migration
  def up
    add_column :variant_overrides, :permission_revoked_at, :datetime, default: nil

    variant_override_hubs = Enterprise.where(id: VariantOverride.all.map(&:hub_id).uniq)

    variant_override_hubs.each do |hub|
      permitting_producer_ids = hub.relationships_as_child
        .with_permission(:create_variant_overrides).map(&:parent_id)

      variant_overrides_with_revoked_permissions = VariantOverride.for_hubs(hub)
        .joins(variant: :product).where("spree_products.supplier_id NOT IN (?)", permitting_producer_ids)

      variant_overrides_with_revoked_permissions.update_all(permission_revoked_at: Time.now)
    end
  end

  def down
    remove_column :variant_overrides, :permission_revoked_at
  end
end
