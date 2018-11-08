class AllowAllSuppliersOwnVariantOverrides < ActiveRecord::Migration
  def up
    # This migration is fixing a detail of previous migration RevokeVariantOverrideswithoutPermissions
    #   Here we allow all variant_overrides where hub_id is the products supplier_id
    #   This is needed when the supplier herself uses the inventory to manage stock and not the catalog
    owned_variant_overrides = VariantOverride.unscoped
      .joins(variant: :product).where("spree_products.supplier_id = variant_overrides.hub_id")

    owned_variant_overrides.update_all(permission_revoked_at: nil)
  end
end

