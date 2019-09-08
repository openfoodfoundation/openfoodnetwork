describe "AdminSimpleCreateOrderCycleCtrl", ->
  ctrl = null
  scope = {}
  OrderCycle = {}
  Enterprise = {}
  EnterpriseFee = {}
  incoming_exchange = {}
  outgoing_exchange = {}

  beforeEach ->
    scope =
      $watch: jasmine.createSpy('$watch')
    order_cycle =
      coordinator_id: 123
      incoming_exchanges: [incoming_exchange]
      outgoing_exchanges: [outgoing_exchange]
    OrderCycle =
      order_cycle: order_cycle
      addSupplier: jasmine.createSpy()
      addDistributor: jasmine.createSpy()
      setExchangeVariants: jasmine.createSpy()
      new: jasmine.createSpy().and.returnValue order_cycle
    Enterprise =
      get: jasmine.createSpy().and.returnValue {id: 123}
      index: jasmine.createSpy()
      suppliedVariants: jasmine.createSpy().and.returnValue('supplied variants')
    EnterpriseFee =
      index: jasmine.createSpy()
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminSimpleCreateOrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  describe "initialisation", ->
    enterprise = {id: 123}
    enterprises = {123: enterprise}

    beforeEach ->
      scope.init(enterprises)

    it "sets up an incoming and outgoing exchange", ->
      expect(OrderCycle.addSupplier).toHaveBeenCalledWith(enterprise.id)
      expect(OrderCycle.addDistributor).toHaveBeenCalledWith(enterprise.id)
      expect(scope.outgoing_exchange).toEqual outgoing_exchange

    it "selects all variants", ->
      expect(Enterprise.suppliedVariants).
        toHaveBeenCalledWith(enterprise.id)

      expect(OrderCycle.setExchangeVariants).
        toHaveBeenCalledWith(incoming_exchange, 'supplied variants', true)

    it "sets the coordinator", ->
      expect(OrderCycle.order_cycle.coordinator_id).toEqual enterprise.id
