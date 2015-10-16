describe 'OrderCycleCtrl', ->
  ctrl = null
  scope = null
  OrderCycle = null

  beforeEach ->
    module 'Darkswarm'
    scope = {}
    OrderCycle =
      order_cycle:
        id: 123
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'OrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle}

  it "puts the order cycle in scope", ->
    expect(scope.order_cycle).toEqual {id: 123}
