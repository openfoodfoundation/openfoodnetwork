describe 'OrderCycleCtrl', ->
  ctrl = null
  scope = null
  event = null
  product_ctrl = null
  OrderCycle = null

  beforeEach ->
    module 'Darkswarm'
    scope = {}
    OrderCycle = 
      order_cycle: "test"
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'OrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle}

  #it "puts the order cycle in scope", ->
    #expect(scope.order_cycle).toEqual "test"
