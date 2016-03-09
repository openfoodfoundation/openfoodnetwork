angular.module("admin.variantOverrides").filter "inventoryVariants", ($filter, InventoryItems) ->
  return (variants, hub_id, views) ->
    return [] if !hub_id
    return $filter('filter')(variants, (variant) ->
      if InventoryItems.inventoryItems.hasOwnProperty(hub_id) && InventoryItems.inventoryItems[hub_id].hasOwnProperty(variant.id)
        if InventoryItems.inventoryItems[hub_id][variant.id].visible
          return views.inventory.visible
        else
          return views.hidden.visible
      else
        return views.new.visible
    , true)
