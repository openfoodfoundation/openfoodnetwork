angular.module("admin.standingOrders").factory "StandingOrder", ($injector, StandingOrderResource) ->
  new class StandingOrder
    standingOrder: new StandingOrderResource()

    constructor: ->
      if $injector.has('standingOrder')
        angular.extend(@standingOrder, $injector.get('standingOrder'))
