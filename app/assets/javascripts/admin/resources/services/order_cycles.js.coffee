angular.module("admin.resources").factory 'OrderCycles', ($q, $injector, OrderCycleResource) ->
  new class OrderCycles
    all: []
    byID: {}
    pristineByID: {}

    constructor: ->
      if $injector.has('orderCycles')
        for orderCycle in $injector.get('orderCycles')
          @all.push orderCycle
          @byID[orderCycle.id] = orderCycle
          @pristineByID[orderCycle.id] = angular.copy(orderCycle)


    index: (params={}, callback=null) ->
      OrderCycleResource.index(params, (data) =>
        for orderCycle in data
          @byID[orderCycle.id] = orderCycle
          @pristineByID[orderCycle.id] = angular.copy(orderCycle)

        (callback || angular.noop)(data)

        data
      )

    save: (order_cycle) ->
      deferred = $q.defer()
      order_cycle.$update({id: order_cycle.id})
      .then( (data) =>
        @pristineByID[order_cycle.id] = angular.copy(order_cycle)
        deferred.resolve(data)
      ).catch (response) ->
        deferred.reject(response)
      deferred.promise

    saved: (order_cycle) ->
      @diff(order_cycle).length == 0

    diff: (order_cycle) ->
      changed = []
      for attr, value of order_cycle when not angular.equals(value, @pristineByID[order_cycle.id][attr])
        changed.push attr unless attr is "$$hashKey"
      changed

    resetAttribute: (order_cycle, attribute) ->
      order_cycle[attribute] = @pristineByID[order_cycle.id][attribute]
