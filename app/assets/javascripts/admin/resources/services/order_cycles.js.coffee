angular.module("admin.resources").factory 'OrderCycles', ($q, $injector, OrderCycleResource, RequestMonitor, StatusMessage) ->
  new class OrderCycles
    all: []
    byID: {}
    pristineByID: {}

    constructor: ->
      if $injector.has('orderCycles')
        @load($injector.get('orderCycles'))

    index: (params={}) ->
      request = OrderCycleResource.index params, (data) => @load(data)
      RequestMonitor.load(request.$promise)
      request

    load: (orderCycles) ->
      for orderCycle in orderCycles when orderCycle.id not in Object.keys(@byID)
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
      for id, orderCycle of @byID when not @saved(orderCycle)
        changed[Object.keys(changed).length] = @changesFor(orderCycle)
      if Object.keys(changed).length > 0
        StatusMessage.display('progress', "Saving...")
        OrderCycleResource.bulkUpdate { order_cycle_set: { collection_attributes: changed } }, (data) =>
          for orderCycle in data
            delete orderCycle.coordinator
            delete orderCycle.producers
            delete orderCycle.distributors
            angular.extend(@byID[orderCycle.id], orderCycle)
            angular.extend(@pristineByID[orderCycle.id], orderCycle)
          form.$setPristine() if form?
          StatusMessage.display('success', t('order_cycles_bulk_update_notice'))
        , (response) =>
          if response.data.errors?
            StatusMessage.display('failure', response.data.errors[0])
          else
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
      ['name', 'orders_open_at','orders_close_at']

    resetAttribute: (order_cycle, attribute) ->
      order_cycle[attribute] = @pristineByID[order_cycle.id][attribute]
