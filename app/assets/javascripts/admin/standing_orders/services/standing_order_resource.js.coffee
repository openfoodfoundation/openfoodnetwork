angular.module("admin.standingOrders").factory 'StandingOrderResource', ($resource) ->
  $resource('/admin/standing_orders/:id/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
      params:
        id: '@id'
  })
