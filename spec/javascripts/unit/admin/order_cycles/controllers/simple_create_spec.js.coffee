describe "AdminSimpleCreateOrderCycleCtrl", ->
  ctrl = null
  scope = null
  OrderCycle = {}
  Enterprise = {}
  ExchangeProduct = {}
  EnterpriseFee = {}
  incoming_exchange = {}
  outgoing_exchange = {}

  beforeEach ->
    scope =
      $watch: jasmine.createSpy('$watch')
      setOutgoingExchange: jasmine.createSpy('setOutgoingExchange')
      loadExchangeProducts: jasmine.createSpy('loadExchangeProducts')
      storeProductsAndSelectAllVariants: jasmine.createSpy('storeProductsAndSelectAllVariants')
    order_cycle =
      coordinator_id: 123
      incoming_exchanges: [incoming_exchange]
      outgoing_exchanges: [outgoing_exchange]
    OrderCycle =
      order_cycle: order_cycle
      addSupplier: jasmine.createSpy('addSupplier')
      addDistributor: jasmine.createSpy('addDistributor')
      setExchangeVariants: jasmine.createSpy('setExchangeVariants')
      new: jasmine.createSpy().and.returnValue order_cycle
    Enterprise =
      get: jasmine.createSpy().and.returnValue {id: 123}
      index: jasmine.createSpy()
      suppliedVariants: jasmine.createSpy().and.returnValue('supplied variants')
    ExchangeProduct =
      index: jasmine.createSpy()
    EnterpriseFee =
      index: jasmine.createSpy()
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminSimpleCreateOrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ExchangeProduct: ExchangeProduct, ocInstance: ocInstance}

  describe "initialisation", ->
    enterprise = {id: 123}
    enterprises = {123: enterprise}

    beforeEach ->
      scope.init(enterprises)

    it "adds enterprise as both the supplier and the distributor", ->
      expect(OrderCycle.addSupplier).toHaveBeenCalledWith(enterprise.id, scope.loadExchangeProducts)
      expect(OrderCycle.addDistributor).toHaveBeenCalledWith(enterprise.id, scope.setOutgoingExchange)

    it "loads exchange products", ->
      incoming_exchange.enterprise_id = enterprise.id

      scope.loadExchangeProducts()

      expect(ExchangeProduct.index).toHaveBeenCalledWith({ enterprise_id: enterprise.id, incoming: true }, scope.storeProductsAndSelectAllVariants)

    it "stores products and selects all variants", ->
      scope.incoming_exchange = incoming_exchange
      incoming_exchange.enterprise_id = enterprise.id
      scope.enterprises = { "#{enterprise.id}": {}}

      scope.storeProductsAndSelectAllVariants()

      expect(Enterprise.suppliedVariants).
        toHaveBeenCalledWith(enterprise.id)
      expect(OrderCycle.setExchangeVariants).
        toHaveBeenCalledWith(incoming_exchange, 'supplied variants', true)

    it "sets the coordinator", ->
      expect(OrderCycle.order_cycle.coordinator_id).toEqual enterprise.id
