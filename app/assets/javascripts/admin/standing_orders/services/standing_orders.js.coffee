angular.module("admin.standingOrders").factory 'StandingOrders', ($q, StandingOrderResource, StandingOrder) ->
  new class StandingOrders
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
    	StandingOrderResource.index params, (data) =>
        @load(data)

    load: (standingOrders) ->
      for standingOrder in standingOrders
        @byID[standingOrder.id] = standingOrder
        @pristineByID[standingOrder.id] = angular.copy(standingOrder)

    afterCreate: (id) ->
      @pristineByID[id] = angular.copy(@byID[id])

    afterUpdate: (id) ->
      @pristineByID[id] = angular.copy(@byID[id])

    afterRemoveItem: (id, deletedItemID) ->
      for item, i in @pristineByID[id].standing_line_items when item.id == deletedItemID
        @pristineByID[id].standing_line_items.splice(i, 1)
