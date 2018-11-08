angular.module("admin.resources").factory 'OrderResource', ($resource) ->
  $resource('/admin/orders/:id/:action.json', {}, {
    'index':
      url: '/api/orders.json'
      method: 'GET'
    'update':
      method: 'PUT'
  })
