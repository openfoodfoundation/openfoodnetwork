angular.module("admin.enterprises").factory 'EnterpriseResource', ($resource) ->
  $resource('/admin/enterprises/:id.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
  })
