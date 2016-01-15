angular.module("admin.variantOverrides").filter "inventoryVariants", ($filter, InventoryItems) ->
  return (variants, hub_id, showHidden) ->
    return [] if !hub_id
    return $filter('filter')(variants, (variant) ->
      if InventoryItems.inventoryItems.hasOwnProperty(hub_id) && InventoryItems.inventoryItems[hub_id].hasOwnProperty(variant.id)
        if showHidden
          return true
        else
          return InventoryItems.inventoryItems[hub_id][variant.id].visible
      else
        false
    , true)
