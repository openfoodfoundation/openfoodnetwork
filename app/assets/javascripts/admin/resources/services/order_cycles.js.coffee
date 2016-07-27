angular.module("admin.resources").factory 'OrderCycles', ($q, $injector, OrderCycleResource, StatusMessage, Enterprises, blankOption) ->
  new class OrderCycles
    all: []
    byID: {}
    pristineByID: {}

    constructor: ->
      if $injector.has('orderCycles')
        @load($injector.get('orderCycles'))

    index: (params={}, callback=null) ->
      OrderCycleResource.index params, (data) =>
        @load(data)
        (callback || angular.noop)(data)
        data

    load: (orderCycles) ->
      for orderCycle in orderCycles
        @all.push orderCycle
        @byID[orderCycle.id] = orderCycle
        @pristineByID[orderCycle.id] = angular.copy(orderCycle)

    save: (order_cycle) ->
      deferred = $q.defer()
      order_cycle.$update({id: order_cycle.id})
      .then( (data) =>
        @pristineByID[order_cycle.id] = angular.copy(order_cycle)
        deferred.resolve(data)
      ).catch (response) ->
        deferred.reject(response)
      deferred.promise

    saveChanges: (form) ->
      changed = {}
      for id, orderCycle of @orderCyclesByID when not @saved(orderCycle)
        changed[Object.keys(changed).length] = @changesFor(orderCycle)
      if Object.keys(changed).length > 0
        StatusMessage.display('progress', "Saving...")
        OrderCycleResource.bulkUpdate { order_cycle_set: { collection_attributes: changed } }, (data) =>
          for orderCycle in data
            angular.extend(@orderCyclesByID[orderCycle.id], orderCycle)
            angular.extend(@pristineByID[orderCycle.id], orderCycle)
            @linkToEnterprises(orderCycle)
          form.$setPristine() if form?
          StatusMessage.display('success', "Order cycles have been updated.")
        , (response) =>
          StatusMessage.display('failure', "Oh no! I was unable to save your changes.")

    saved: (order_cycle) ->
      @diff(order_cycle).length == 0

    diff: (order_cycle) ->
      changed = []
      for attr, value of order_cycle when not angular.equals(value, @pristineByID[order_cycle.id][attr])
        changed.push attr if attr in @attrsToSave()
      changed

    changesFor: (orderCycle) ->
      changes = { id: orderCycle.id }
      for attr, value of orderCycle when not angular.equals(value, @pristineByID[orderCycle.id][attr])
        changes[attr] = orderCycle[attr] if attr in @attrsToSave()
      changes

    attrsToSave: ->
      ['orders_open_at','orders_close_at']

    resetAttribute: (order_cycle, attribute) ->
      order_cycle[attribute] = @pristineByID[order_cycle.id][attribute]
