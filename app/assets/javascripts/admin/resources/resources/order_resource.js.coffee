angular.module("admin.resources").factory 'OrderResource', ($resource) ->
  $resource('/admin/orders/:id/:action.json', {}, {
    'index':
      url: '/api/orders.json'
      method: 'GET'
    'update':
      method: 'PUT'
    'capture':
      url: '/api/orders/:id/capture.json'
      method: 'PUT'
      params:
        id: '@id'
    'ship':
      url: '/api/orders/:id/ship.json'
      method: 'PUT'
      params:
        id: '@id'
  })
