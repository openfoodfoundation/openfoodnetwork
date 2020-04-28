Darkswarm.factory 'ShopsResource', ($resource) ->
  $resource('/api/shops/:id.json', {}, {
    'closed_shops':
      method: 'GET'
      isArray: true
      url: '/api/shops/closed_shops.json'
  })
