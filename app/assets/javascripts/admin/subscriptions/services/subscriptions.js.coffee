angular.module("admin.standingOrders").factory 'StandingOrders', ($q, StandingOrderResource, StandingOrder, RequestMonitor) ->
  new class StandingOrders
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
      request = StandingOrderResource.index params, (data) => @load(data)
      RequestMonitor.load(request.$promise)
      request

    load: (standingOrders) ->
      for standingOrder in standingOrders
        @byID[standingOrder.id] = standingOrder
        @pristineByID[standingOrder.id] = angular.copy(standingOrder)

    afterCreate: (id) ->
      return unless @byID[id]?
      @pristineByID[id] = angular.copy(@byID[id])

    afterUpdate: (id) ->
      return unless @byID[id]?
      @pristineByID[id] = angular.copy(@byID[id])

    afterRemoveItem: (id, deletedItemID) ->
      return unless @pristineByID[id]?
      for item, i in @pristineByID[id].standing_line_items when item.id == deletedItemID
        @pristineByID[id].standing_line_items.splice(i, 1)
