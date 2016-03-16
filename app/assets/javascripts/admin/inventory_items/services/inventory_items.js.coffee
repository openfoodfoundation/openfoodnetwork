angular.module("admin.inventoryItems").factory "InventoryItems", (inventoryItems, InventoryItemResource) ->
  new class InventoryItems
    inventoryItems: {}
    errors: {}

    constructor: ->
      for ii in inventoryItems
        @inventoryItems[ii.enterprise_id] ||= {}
        @inventoryItems[ii.enterprise_id][ii.variant_id] = new InventoryItemResource(ii)

    setVisibility: (hub_id, variant_id, visible) ->
      if @inventoryItems[hub_id] && @inventoryItems[hub_id][variant_id]
        inventory_item = angular.extend(angular.copy(@inventoryItems[hub_id][variant_id]), {visible: visible})
        InventoryItemResource.update {id: inventory_item.id}, inventory_item, (data) =>
          @inventoryItems[hub_id][variant_id] = data
        , (response) =>
          @errors[hub_id] ||= {}
          @errors[hub_id][variant_id] = response.data.errors
      else
        InventoryItemResource.save {enterprise_id: hub_id, variant_id: variant_id, visible: visible}, (data) =>
          @inventoryItems[hub_id] ||= {}
          @inventoryItems[hub_id][variant_id] = data
        , (response) =>
          @errors[hub_id] ||= {}
          @errors[hub_id][variant_id] = response.data.errors
