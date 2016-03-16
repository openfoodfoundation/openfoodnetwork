angular.module("admin.inventoryItems").factory 'InventoryItemResource', ($resource) ->
  $resource('/admin/inventory_items/:id/:action.json', {}, {
    'update':
      method: 'PUT'
  })
