class PopulateInventories < ActiveRecord::Migration
  def up
    # If hubs are actively using overrides, populate their inventories with all variants they have permission to override
    # Otherwise leave their inventories empty

    hubs_using_overrides = Enterprise.joins("LEFT OUTER JOIN variant_overrides ON variant_overrides.hub_id = enterprises.id")
      .where("variant_overrides.id IS NOT NULL").select("DISTINCT enterprises.*")

    hubs_using_overrides.each do |hub|
      overridable_producers = OpenFoodNetwork::Permissions.new(hub.owner).variant_override_producers

      variants = Spree::Variant.where(is_master: false, product_id: Spree::Product.not_deleted.where(supplier_id: overridable_producers))

      variants.each do |variant|
        InventoryItem.create(enterprise: hub, variant: variant, visible: true)
      end
    end
  end

  def down
  end
end
