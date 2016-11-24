angular.module("admin.standingOrders").factory "StandingOrder", ($injector, StandingOrderResource) ->
  class StandingOrder extends StandingOrderResource

    constructor: ->
      if $injector.has('standingOrder')
        angular.extend(@, $injector.get('standingOrder'))
