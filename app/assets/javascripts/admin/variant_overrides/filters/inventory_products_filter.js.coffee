angular.module("admin.variantOverrides").filter "inventoryProducts", ($filter, InventoryItems) ->
  return (products, hub_id, showHidden) ->
    return [] if !hub_id
    return $filter('filter')(products, (product) ->
      for variant in product.variants
        if InventoryItems.inventoryItems.hasOwnProperty(hub_id) && InventoryItems.inventoryItems[hub_id].hasOwnProperty(variant.id)
          if showHidden
            return true
          else
            return true if InventoryItems.inventoryItems[hub_id][variant.id].visible
      false
    , true)
