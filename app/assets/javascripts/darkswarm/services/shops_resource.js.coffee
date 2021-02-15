Darkswarm.factory 'ShopsResource', ($resource) ->
  $resource('/api/legacy/shops/:id.json', {}, {
    'closed_shops':
      method: 'GET'
      isArray: true
      url: '/api/legacy/shops/closed_shops.json'
  })
