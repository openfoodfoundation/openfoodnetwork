angular.module("admin.resources").factory 'Orders', ($q, OrderResource, RequestMonitor) ->
  new class Orders
    all: []
    byID: {}
    pristineByID: {}
    pagination: {}

    index: (params={}, callback=null) ->
      request = OrderResource.index params, (data) =>
        @load(data)
        (callback || angular.noop)(data)
      @all.$promise = request.$promise
      @all

    load: (data) ->
      angular.extend(@pagination, data.pagination)
      @clearData()
      for order in data.orders
        @all.push order
        @byID[order.id] = order
        @pristineByID[order.id] = angular.copy(order)

    clearData: ->
      @all.length = 0
      @byID = {}
      @pristineByID = {}

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

    capture: (order) ->
      @processAction('capture', order)

    ship: (order) ->
      @processAction('ship', order)

    processAction: (action, order) ->
      OrderResource[action] {id: order.number}, (data) =>
        if data.id
          angular.merge(order, data)
          data
      , (response) =>
        response.data

    resetAttribute: (order, attribute) ->
      order[attribute] = @pristineByID[order.id][attribute]
