angular.module("admin.enterprises").factory 'EnterpriseResource', ($resource) ->
  $resource('/admin/enterprises/:id/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
  })
