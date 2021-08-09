angular.module('Darkswarm').factory 'ShopsResource', ($resource) ->
  $resource('/api/v0/shops/:id.json', {}, {
    'closed_shops':
      method: 'GET'
      isArray: true
      url: '/api/v0/shops/closed_shops.json'
  })
