describe "AdminSimpleCreateOrderCycleCtrl", ->
  ctrl = null
  scope = {}
  OrderCycle = {}
  Enterprise = {}
  EnterpriseFee = {}
  incoming_exchange = {}
  outgoing_exchange = {}

  beforeEach ->
    scope = {}
    OrderCycle =
      order_cycle:
        incoming_exchanges: [incoming_exchange]
        outgoing_exchanges: [outgoing_exchange]
      addSupplier: jasmine.createSpy()
      addDistributor: jasmine.createSpy()
      setExchangeVariants: jasmine.createSpy()
    Enterprise =
      index: jasmine.createSpy()
      suppliedVariants: jasmine.createSpy().andReturn('supplied variants')
    EnterpriseFee =
      index: jasmine.createSpy()

    module('admin.order_cycles')
    inject ($controller) ->
      ctrl = $controller 'AdminSimpleCreateOrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee}

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