Darkswarm.factory 'OrderCycleResource', ($resource) ->
  $resource('/api/order_cycles/:id.json', {}, {
    'products':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/products.json'
      params:
        id: '@id'
    'taxons':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/taxons.json'
      params:
        id: '@id'
    'properties':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/properties.json'
      params:
        id: '@id'
  })
