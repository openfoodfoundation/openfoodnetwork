angular.module("admin.resources").factory 'OrderResource', ($resource) ->
  $resource('/admin/orders/:id/:action.json', {}, {
    'index':
      url: '/api/legacy/orders.json'
      method: 'GET'
    'update':
      method: 'PUT'
    'capture':
      url: '/api/legacy/orders/:id/capture.json'
      method: 'PUT'
      params:
        id: '@id'
    'ship':
      url: '/api/legacy/orders/:id/ship.json'
      method: 'PUT'
      params:
        id: '@id'
  })
