angular.module('Darkswarm').factory 'OrderCycleResource', ($resource) ->
  $resource('/api/v0/order_cycles/:id.json', {}, {
    'products':
      method: 'GET'
      isArray: true
      url: '/api/v0/order_cycles/:id/products.json'
      params:
        id: '@id'
    'taxons':
      method: 'GET'
      isArray: true
      url: '/api/v0/order_cycles/:id/taxons.json'
      params:
        id: '@id'
    'properties':
      method: 'GET'
      isArray: true
      url: '/api/v0/order_cycles/:id/properties.json'
      params:
        id: '@id'
  })
