angular.module("admin.standingOrders").factory 'StandingOrders', ($q, StandingOrderResource, StandingOrder) ->
  new class StandingOrders
    all: []
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
    	StandingOrderResource.index params, (data) =>
        @load(data)

    load: (standingOrders) ->
      @clear()
      for standingOrder in standingOrders
        @all.push standingOrder
        @byID[standingOrder.id] = standingOrder
        @pristineByID[standingOrder.id] = angular.copy(standingOrder)

    afterCreate: (id) ->
      return unless @byID[id]?
      @pristineByID[id] = angular.copy(@byID[id])

    afterUpdate: (id) ->
      return unless @byID[id]?
      @pristineByID[id] = angular.copy(@byID[id])

    afterCancel: (item) ->
      i = @all.indexOf(item)
      @all.splice(i,1) if i >= 0
      delete @byID[item.id]
      delete @pristineByID[item.id]

    afterRemoveItem: (id, deletedItemID) ->
      return unless @pristineByID[id]?
      for item, i in @pristineByID[id].standing_line_items when item.id == deletedItemID
        @pristineByID[id].standing_line_items.splice(i, 1)

    clear: ->
      @all.length = 0
