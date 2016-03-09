class RepopulateInventories < ActiveRecord::Migration
  # Previous version of this migration (20160218235221) relied on Permissions#variant_override_producers
  # which was then changed, meaning that an incomplete set of variants were added to inventories of most hubs
  # Re-running this now will ensure that all permitted variants (including those allowed by 20160224034034) are
  # added to the relevant inventories

  def up
    # If hubs are actively using overrides, populate their inventories with all variants they have permission to override
    # Otherwise leave their inventories empty

    hubs_using_overrides = Enterprise.joins("LEFT OUTER JOIN variant_overrides ON variant_overrides.hub_id = enterprises.id")
      .where("variant_overrides.id IS NOT NULL").select("DISTINCT enterprises.*")

    hubs_using_overrides.each do |hub|
      overridable_producer_ids = hub.relationships_as_child.with_permission(:create_variant_overrides).map(&:parent_id) | [hub.id]

      variants = Spree::Variant.where(is_master: false, product_id: Spree::Product.not_deleted.where(supplier_id: overridable_producer_ids))

      variants_to_add = variants.joins("LEFT OUTER JOIN (SELECT * from inventory_items WHERE enterprise_id = #{hub.id}) AS o_inventory_items ON o_inventory_items.variant_id = spree_variants.id")
      .where('o_inventory_items.id IS NULL')

      variants_to_add.each do |variant|
        inventory_item = InventoryItem.create(enterprise: hub, variant: variant, visible: true)
      end
    end
  end

  def down
  end
end
