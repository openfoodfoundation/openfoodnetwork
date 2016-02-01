angular.module("admin.variantOverrides").filter "newInventoryProducts", ($filter, InventoryItems) ->
  return (products, hub_id) ->
    return [] if !hub_id
    return products unless InventoryItems.inventoryItems.hasOwnProperty(hub_id)
    return $filter('filter')(products, (product) ->
      for variant in product.variants
        return true if !InventoryItems.inventoryItems[hub_id].hasOwnProperty(variant.id)
      false
    , true)
