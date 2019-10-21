Darkswarm.factory 'OrderCycleResource', ($resource) ->
  $resource('/api/order_cycles/:id', {}, {
    'products':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/products'
      params:
        id: '@id'
    'taxons':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/taxons'
      params:
        id: '@id'
    'properties':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/properties'
      params:
        id: '@id'
  })
