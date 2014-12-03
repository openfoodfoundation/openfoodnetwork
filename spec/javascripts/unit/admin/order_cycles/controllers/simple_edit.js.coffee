describe "AdminSimpleEditOrderCycleCtrl", ->
  ctrl = null
  scope = {}
  location = {}
  OrderCycle = {}
  Enterprise = {}
  EnterpriseFee = {}
  incoming_exchange = {}
  outgoing_exchange = {}

  beforeEach ->
    scope = {}
    location =
      absUrl: ->
        'example.com/admin/order_cycles/27/edit'
    OrderCycle =
      order_cycle:
        incoming_exchanges: [incoming_exchange]
        outgoing_exchanges: [outgoing_exchange]
      load: jasmine.createSpy()
    Enterprise =
      index: jasmine.createSpy()
    EnterpriseFee =
      index: jasmine.createSpy()

    module('admin.order_cycles')
    inject ($controller) ->
      ctrl = $controller 'AdminSimpleEditOrderCycleCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee}

  describe "initialisation", ->
    enterprise = {id: 123}
    enterprises = {123: enterprise}

    beforeEach ->
      scope.init(enterprises)

    it "sets the outgoing exchange", ->
      expect(scope.outgoing_exchange).toEqual outgoing_exchange
