angular.module("admin.resources").factory 'Orders', ($q, OrderResource, RequestMonitor) ->
  new class Orders
    byID: {}
    pristineByID: {}
    pagination: {}

    index: (params={}, callback=null) ->
      request = OrderResource.index params, (data) =>
        @load(data)
        (callback || angular.noop)(data)
      RequestMonitor.load(request.$promise)
      request

    load: (data) ->
      angular.extend(@pagination, data.pagination)
      for order in data.orders
        @byID[order.id] = order
        @pristineByID[order.id] = angular.copy(order)

    save: (order) ->
      deferred = $q.defer()
      order.$update({id: order.number})
      .then( (data) =>
        @pristineByID[order.id] = angular.copy(order)
        deferred.resolve(data)
      ).catch (response) ->
        deferred.reject(response)
      deferred.promise

    saved: (order) ->
      @diff(order).length == 0

    diff: (order) ->
      changed = []
      for attr, value of order when not angular.equals(value, @pristineByID[order.id][attr])
        changed.push attr unless attr is "$$hashKey"
      changed

    resetAttribute: (order, attribute) ->
      order[attribute] = @pristineByID[order.id][attribute]
