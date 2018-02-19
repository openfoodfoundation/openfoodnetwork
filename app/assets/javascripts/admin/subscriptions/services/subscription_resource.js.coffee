angular.module("admin.subscriptions").factory 'SubscriptionResource', ($resource, SubscriptionActions) ->
  resource = $resource('/admin/subscriptions/:id/:action.json', {}, {
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
        open_orders: '@open_orders'
    'pause':
      method: 'PUT'
      params:
        id: '@id'
        action: 'pause'
        open_orders: '@open_orders'
    'unpause':
      method: 'PUT'
      params:
        id: '@id'
        action: 'unpause'
  })

  angular.extend(resource.prototype, SubscriptionActions)

  resource
