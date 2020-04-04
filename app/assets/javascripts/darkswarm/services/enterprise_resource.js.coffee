Darkswarm.factory 'EnterpriseResource', ($resource) ->
  $resource('/enterprise/:id.json', {}, {
    'relatives':
      method: 'GET'
      url: '/enterprises/:id/relatives.json'
      isArray: true
      cache: true
    'closed_shops':
      method: 'GET'
      isArray: true
      url: '/api/enterprises/closed_shops.json'
  })
