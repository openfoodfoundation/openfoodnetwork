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
    'pause':
      method: 'PUT'
      params:
        id: '@id'
        action: 'pause'
    'unpause':
      method: 'PUT'
      params:
        id: '@id'
        action: 'unpause'
  })

  angular.extend(resource.prototype, StandingOrderPrototype)

  resource
