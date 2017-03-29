angular.module("admin.resources").factory 'Orders', ($q, $injector, OrderResource) ->
  new class Orders
    all: []
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
    	OrderResource.index params, (data) =>
        @load(data)
        (callback || angular.noop)(data)

    load: (orders) ->
      for order in orders
        @all.push order
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

    linkToDistributors: ->
      if $injector.has('Enterprises')
        enterprisesByID = $injector.get('Enterprises').byID
        for id, order of @byID
          order.distributor = enterprisesByID[order.distributor.id] if order.distributor?
