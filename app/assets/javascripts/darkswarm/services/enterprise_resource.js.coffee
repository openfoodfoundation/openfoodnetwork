angular.module('Darkswarm').factory 'EnterpriseResource', ($resource) ->
  $resource('/enterprise/:id.json', {}, {
    'relatives':
      method: 'GET'
      url: '/enterprises/:id/relatives.json'
      isArray: true
      cache: true
  })
