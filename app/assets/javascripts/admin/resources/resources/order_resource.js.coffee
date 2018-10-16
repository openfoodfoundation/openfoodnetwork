angular.module("admin.resources").factory 'OrderResource', ($resource) ->
  $resource('/admin/orders/:id/:action.json', {}, {
    'index':
      method: 'GET'
    'update':
      method: 'PUT'
  })
