angular.module("admin.orders").factory 'Orders', ($q, OrderResource) ->
  new class Orders
    ordersByID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
    	OrderResource.index params, (data) =>
        for order in data
          @ordersByID[order.id] = order
          @pristineByID[order.id] = angular.copy(order)

        (callback || angular.noop)(data)

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
