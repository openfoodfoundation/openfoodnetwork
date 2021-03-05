angular.module("admin.resources").factory 'OrderResource', ($resource) ->
  $resource('/admin/orders/:id/:action.json', {}, {
    'index':
      url: '/api/v0/orders.json'
      method: 'GET'
    'update':
      method: 'PUT'
    'capture':
      url: '/api/v0/orders/:id/capture.json'
      method: 'PUT'
      params:
        id: '@id'
    'ship':
      url: '/api/v0/orders/:id/ship.json'
      method: 'PUT'
      params:
        id: '@id'
  })
