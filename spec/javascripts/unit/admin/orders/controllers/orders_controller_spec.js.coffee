describe "ordersCtrl", ->
  ctrl = null
  scope = {}
  attrs = {}
  shops = []
  orderCycles = [
    {id: 10, name: 'Ten', status: 'open', distributors: [{id: 1, name: 'One'}]}
    {id: 20, name: 'Twenty', status: 'closed', distributors: [{id: 2, name: 'Two', status: 'closed'}]}
  ]
  SortOptions = {
    predicate: "",
    reverse: false
  }

  beforeEach ->
    scope = {}
    shops = []
    orderCycles = [
      {id: 10, name: 'Ten', status: 'open', distributors: [{id: 1, name: 'One'}]}
      {id: 20, name: 'Twenty', status: 'closed', distributors: [{id: 2, name: 'Two', status: 'closed'}]}
    ]

    module 'admin.orders', ($provide)->
      $provide.provider('shops', shops)
      $provide.provider('orderCycles', orderCycles)
    inject (_$injector_, $controller) ->
      $injector = _$injector_
      ctrl = $controller 'ordersCtrl', {$scope: scope, $attrs: attrs, $injector: $injector, SortOptions: SortOptions}

  it "initialises name_and_status", ->
    expect(scope.orderCycles[0].name_and_status).toEqual "Ten (open)"
    expect(scope.orderCycles[1].name_and_status).toEqual "Twenty (closed)"

  describe "finding valid order cycles for a distributor", ->
    order_cycle = {id: 10, distributors: [{id: 1, name: 'One'}]}

    it "returns true when the order cycle includes the distributor", ->
      scope.distributor_id = '1'
      expect(scope.validOrderCycle(order_cycle, 1, [order_cycle])).toBe true

    it "returns false otherwise", ->
      scope.distributor_id = '2'
      expect(scope.validOrderCycle(order_cycle, 1, [order_cycle])).toBe false

  describe "checking if a distributor has order cycles", ->
    it "returns true when it does", ->
      distributor = {id: 1}
      expect(scope.distributorHasOrderCycles(distributor)).toBe true

    it "returns false otherwise", ->
      distributor = {id: 3}
      expect(scope.distributorHasOrderCycles(distributor)).toBe false
