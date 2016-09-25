angular.module("admin.standingOrders").factory 'StandingOrderResource', ($resource) ->
  $resource('/admin/standing_orders/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'create':
      method: 'POST'
  })
