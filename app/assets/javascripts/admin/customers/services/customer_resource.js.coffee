angular.module("admin.customers").factory 'CustomerResource', ($resource) ->
  $resource('/admin/customers.json', {}, {
    'index':
      method: 'GET'
      isArray: true
      params:
        enterprise_id: '@enterprise_id'
  })
