angular.module("admin.standingOrders").factory 'StandingOrderResource', ($resource, StandingOrderPrototype) ->
  resource = $resource('/admin/standing_orders/:id/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
      params:
        id: '@id'
    'cancel':
      method: 'PUT'
      params:
        id: '@id'
        action: 'cancel'
  })

  angular.extend(resource.prototype, StandingOrderPrototype)

  resource
