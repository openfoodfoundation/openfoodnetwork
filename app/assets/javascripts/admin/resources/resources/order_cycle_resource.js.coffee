angular.module("admin.resources").factory 'OrderCycleResource', ($resource) ->
  $resource('/admin/order_cycles/:id/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
    'bulkUpdate':
      method: 'POST'
      isArray: true
      params:
        action: 'bulk_update'
  })
