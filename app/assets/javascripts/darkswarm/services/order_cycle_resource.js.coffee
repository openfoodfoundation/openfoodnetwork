Darkswarm.factory 'OrderCycleResource', ($resource) ->
  $resource('/api/order_cycles/:id', {}, {
    'products':
      method: 'GET'
      isArray: true
      url: '/api/order_cycles/:id/products'
      params:
        id: '@id'
  })
