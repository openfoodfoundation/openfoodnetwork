angular.module("admin.variantOverrides").filter "inventoryProducts", ($filter, InventoryItems) ->
  return (products, hub_id, views) ->
    return [] if !hub_id
    return $filter('filter')(products, (product) ->
      for variant in product.variants
        if InventoryItems.inventoryItems.hasOwnProperty(hub_id) && InventoryItems.inventoryItems[hub_id].hasOwnProperty(variant.id)
          if InventoryItems.inventoryItems[hub_id][variant.id].visible
            # Important to only return if true, as other variants for this product might be visible
            return true if views.inventory.visible
          else
            # Important to only return if true, as other variants for this product might be visible
            return true if views.hidden.visible
        else
          # Important to only return if true, as other variants for this product might be visible
          return true if views.new.visible
      false
    , true)
