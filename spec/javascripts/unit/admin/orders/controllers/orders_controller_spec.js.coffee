describe "ordersCtrl", ->
  ctrl = null
  scope = {}
  attrs = {}
  shops = []
  orderCycles = [
    {id: 10, distributors: [{id: 1, name: 'One'}]}
    {id: 20, distributors: [{id: 2, name: 'Two'}]}
  ]

  beforeEach ->
    scope = {}

    module('admin.orders')
    inject ($controller) ->
      ctrl = $controller 'ordersCtrl', {$scope: scope, $attrs: attrs, shops: shops, orderCycles: orderCycles}


  describe "finding valid order cycles for a distributor", ->
    order_cycle = {id: 10, distributors: [{id: 1, name: 'One'}]}

    it "returns true when the order cycle includes the distributor", ->
      scope.distributor_id = '1'
      expect(scope.validOrderCycle(order_cycle, 1, [order_cycle])).toBe true

    it "returns false otherwise", ->
      scope.distributor_id = '2'
      expect(scope.validOrderCycle(order_cycle, 1, [order_cycle])).toBe false
