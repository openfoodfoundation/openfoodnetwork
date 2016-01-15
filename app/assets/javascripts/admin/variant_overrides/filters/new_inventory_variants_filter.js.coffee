angular.module("admin.variantOverrides").filter "newInventoryVariants", ($filter, InventoryItems) ->
  return (variants, hub_id) ->
    return [] if !hub_id
    return variants unless InventoryItems.inventoryItems.hasOwnProperty(hub_id)
    return $filter('filter')(variants, (variant) ->
       !InventoryItems.inventoryItems[hub_id].hasOwnProperty(variant.id)
    , true)
