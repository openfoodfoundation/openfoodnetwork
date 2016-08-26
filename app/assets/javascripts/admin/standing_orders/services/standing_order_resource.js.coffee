angular.module("admin.standingOrders").factory 'StandingOrderResource', ($resource) ->
  $resource('/admin/standing_orders/:action.json', {}, {
    'create':
      method: 'POST'
  })
