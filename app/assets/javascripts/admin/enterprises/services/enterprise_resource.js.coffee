angular.module("admin.enterprises").factory 'EnterpriseResource', ($resource) ->
  $resource('/admin/enterprises.json', {}, {
    'index':
      method: 'GET'
      isArray: true
  })
