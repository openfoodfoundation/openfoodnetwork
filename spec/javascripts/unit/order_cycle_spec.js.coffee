describe 'OrderCycle controllers', ->

  describe 'AdminCreateOrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    OrderCycle = null
    Enterprise = null
    EnterpriseFee = null

    beforeEach ->
      scope =
        order_cycle_form: jasmine.createSpyObj('order_cycle_form', ['$dirty'])
        $watch: jasmine.createSpy('$watch')
      event =
        preventDefault: jasmine.createSpy('preventDefault')
      OrderCycle =
        exchangeSelectedVariants: jasmine.createSpy('exchangeSelectedVariants').and.returnValue('variants selected')
        productSuppliedToOrderCycle: jasmine.createSpy('productSuppliedToOrderCycle').and.returnValue('product supplied')
        variantSuppliedToOrderCycle: jasmine.createSpy('variantSuppliedToOrderCycle').and.returnValue('variant supplied')
        exchangeDirection: jasmine.createSpy('exchangeDirection').and.returnValue('exchange direction')
        toggleProducts: jasmine.createSpy('toggleProducts')
        setExchangeVariants: jasmine.createSpy('setExchangeVariants')
        addSupplier: jasmine.createSpy('addSupplier')
        addDistributor: jasmine.createSpy('addDistributor')
        removeExchange: jasmine.createSpy('removeExchange')
        addCoordinatorFee: jasmine.createSpy('addCoordinatorFee')
        removeCoordinatorFee: jasmine.createSpy('removeCoordinatorFee')
        addExchangeFee: jasmine.createSpy('addExchangeFee')
        removeExchangeFee: jasmine.createSpy('removeExchangeFee')
        removeDistributionOfVariant: jasmine.createSpy('removeDistributionOfVariant')
        create: jasmine.createSpy('create')
        new: jasmine.createSpy('new').and.returnValue "my order cycle"
      Enterprise =
        index: jasmine.createSpy('index').and.returnValue('enterprises list')
        supplied_products: 'supplied products'
        suppliedVariants: jasmine.createSpy('suppliedVariants').and.returnValue('supplied variants')
        totalVariants: jasmine.createSpy('totalVariants').and.returnValue('variants total')
      EnterpriseFee =
        index: jasmine.createSpy('index').and.returnValue('enterprise fees list')
        forEnterprise: jasmine.createSpy('forEnterprise').and.returnValue('enterprise fees for enterprise')
      ocInstance = {}

      module('admin.orderCycles')
      inject ($controller) ->
        ctrl = $controller 'AdminCreateOrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}


    it 'Loads enterprises and supplied products', ->
      expect(Enterprise.index).toHaveBeenCalled()
      expect(scope.enterprises).toEqual('enterprises list')
      expect(scope.supplied_products).toEqual('supplied products')

    it 'Loads enterprise fees', ->
      expect(EnterpriseFee.index).toHaveBeenCalled()
      expect(scope.enterprise_fees).toEqual('enterprise fees list')

    it 'Loads order cycles', ->
      expect(scope.order_cycle).toEqual('my order cycle')

    describe 'Reporting when all resources are loaded', ->
      beforeEach inject (RequestMonitor) ->
        RequestMonitor.loading = false
        Enterprise.loaded = true
        EnterpriseFee.loaded = true
        OrderCycle.loaded = true

      it 'returns true when all resources are loaded', ->
        expect(scope.loaded()).toBe(true)

      it 'returns false otherwise', ->
        EnterpriseFee.loaded = false
        expect(scope.loaded()).toBe(false)

    it "delegates suppliedVariants to Enterprise", ->
      expect(scope.suppliedVariants('enterprise_id')).toEqual('supplied variants')
      expect(Enterprise.suppliedVariants).toHaveBeenCalledWith('enterprise_id')

    it 'Delegates exchangeSelectedVariants to OrderCycle', ->
      expect(scope.exchangeSelectedVariants('exchange')).toEqual('variants selected')
      expect(OrderCycle.exchangeSelectedVariants).toHaveBeenCalledWith('exchange')

    it "delegates setExchangeVariants to OrderCycle", ->
      scope.setExchangeVariants('exchange', 'variants', 'selected')
      expect(OrderCycle.setExchangeVariants).toHaveBeenCalledWith('exchange', 'variants', 'selected')

    it 'Delegates enterpriseTotalVariants to Enterprise', ->
      expect(scope.enterpriseTotalVariants('enterprise')).toEqual('variants total')
      expect(Enterprise.totalVariants).toHaveBeenCalledWith('enterprise')

    it 'Delegates productSuppliedToOrderCycle to OrderCycle', ->
      expect(scope.productSuppliedToOrderCycle('product')).toEqual('product supplied')
      expect(OrderCycle.productSuppliedToOrderCycle).toHaveBeenCalledWith('product')

    it 'Delegates variantSuppliedToOrderCycle to OrderCycle', ->
      expect(scope.variantSuppliedToOrderCycle('variant')).toEqual('variant supplied')
      expect(OrderCycle.variantSuppliedToOrderCycle).toHaveBeenCalledWith('variant')

    it 'Delegates exchangeDirection to OrderCycle', ->
      expect(scope.exchangeDirection('exchange')).toEqual('exchange direction')
      expect(OrderCycle.exchangeDirection).toHaveBeenCalledWith('exchange')

    it 'Finds enterprises participating in the order cycle that have fees', ->
      scope.enterprises =
        1: {id: 1, name: 'Eaterprises'}
        2: {id: 2, name: 'Pepper Tree Place'}
        3: {id: 3, name: 'South East'}
      OrderCycle.participatingEnterpriseIds = jasmine.createSpy('participatingEnterpriseIds').and.returnValue([2])
      EnterpriseFee.enterprise_fees = [ {enterprise_id: 2} ] # Pepper Tree Place has a fee
      expect(scope.enterprisesWithFees()).toEqual([
        {id: 2, name: 'Pepper Tree Place'}
        ])

    it 'Delegates enterpriseFeesForEnterprise to EnterpriseFee', ->
      scope.enterpriseFeesForEnterprise('123')
      expect(EnterpriseFee.forEnterprise).toHaveBeenCalledWith(123)

    it 'Adds order cycle suppliers', ->
      scope.new_supplier_id = 'new supplier id'
      scope.addSupplier(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addSupplier).toHaveBeenCalledWith('new supplier id')

    it 'Adds order cycle distributors', ->
      scope.new_distributor_id = 'new distributor id'
      scope.addDistributor(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addDistributor).toHaveBeenCalledWith('new distributor id')

    it 'Removes order cycle exchanges', ->
      scope.removeExchange(event, 'exchange')
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.removeExchange).toHaveBeenCalledWith('exchange')

    it 'Adds coordinator fees', ->
      scope.addCoordinatorFee(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addCoordinatorFee).toHaveBeenCalled()

    it 'Removes coordinator fees', ->
      scope.removeCoordinatorFee(event, 0)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.removeCoordinatorFee).toHaveBeenCalledWith(0)

    it 'Adds exchange fees', ->
      scope.addExchangeFee(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addExchangeFee).toHaveBeenCalled()

    it 'Removes exchange fees', ->
      scope.removeExchangeFee(event, 'exchange', 0)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.removeExchangeFee).toHaveBeenCalledWith('exchange', 0)

    it 'Removes distribution of a variant', ->
      scope.removeDistributionOfVariant('variant')
      expect(OrderCycle.removeDistributionOfVariant).toHaveBeenCalledWith('variant')

    it 'Submits the order cycle via OrderCycle create', ->
      eventMock = {preventDefault: jasmine.createSpy()}
      scope.submit(eventMock,'/admin/order_cycles')
      expect(eventMock.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.create).toHaveBeenCalledWith('/admin/order_cycles')

  describe 'AdminEditOrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    location = null
    OrderCycle = null
    Enterprise = null
    EnterpriseFee = null

    beforeEach ->
      scope =
        order_cycle_form: jasmine.createSpyObj('order_cycle_form', ['$dirty', '$setPristine'])
        $watch: jasmine.createSpy('$watch')
      event =
        preventDefault: jasmine.createSpy('preventDefault')
      location =
        absUrl: ->
          'example.com/admin/order_cycles/27/edit'
      OrderCycle =
        load: jasmine.createSpy('load')
        exchangeSelectedVariants: jasmine.createSpy('exchangeSelectedVariants').and.returnValue('variants selected')
        productSuppliedToOrderCycle: jasmine.createSpy('productSuppliedToOrderCycle').and.returnValue('product supplied')
        variantSuppliedToOrderCycle: jasmine.createSpy('variantSuppliedToOrderCycle').and.returnValue('variant supplied')
        exchangeDirection: jasmine.createSpy('exchangeDirection').and.returnValue('exchange direction')
        toggleProducts: jasmine.createSpy('toggleProducts')
        setExchangeVariants: jasmine.createSpy('setExchangeVariants')
        addSupplier: jasmine.createSpy('addSupplier')
        addDistributor: jasmine.createSpy('addDistributor')
        removeExchange: jasmine.createSpy('removeExchange')
        addCoordinatorFee: jasmine.createSpy('addCoordinatorFee')
        removeCoordinatorFee: jasmine.createSpy('removeCoordinatorFee')
        addExchangeFee: jasmine.createSpy('addExchangeFee')
        removeExchangeFee: jasmine.createSpy('removeExchangeFee')
        removeDistributionOfVariant: jasmine.createSpy('removeDistributionOfVariant')
        update: jasmine.createSpy('update')
      Enterprise =
        index: jasmine.createSpy('index').and.returnValue('enterprises list')
        supplied_products: 'supplied products'
        suppliedVariants: jasmine.createSpy('suppliedVariants').and.returnValue('supplied variants')
        totalVariants: jasmine.createSpy('totalVariants').and.returnValue('variants total')
      EnterpriseFee =
        index: jasmine.createSpy('index').and.returnValue('enterprise fees list')
        forEnterprise: jasmine.createSpy('forEnterprise').and.returnValue('enterprise fees for enterprise')

      module('admin.orderCycles')
      inject ($controller) ->
        ctrl = $controller 'AdminEditOrderCycleCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee}

    it 'Loads enterprises and supplied products', ->
      expect(Enterprise.index).toHaveBeenCalled()
      expect(scope.enterprises).toEqual('enterprises list')
      expect(scope.supplied_products).toEqual('supplied products')

    it 'Loads enterprise fees', ->
      expect(EnterpriseFee.index).toHaveBeenCalled()
      expect(scope.enterprise_fees).toEqual('enterprise fees list')

    it 'Loads order cycles', ->
      expect(OrderCycle.load).toHaveBeenCalledWith('27')

    describe 'Reporting when all resources are loaded', ->
      beforeEach inject (RequestMonitor) ->
        RequestMonitor.loading = false
        Enterprise.loaded = true
        EnterpriseFee.loaded = true
        OrderCycle.loaded = true

      it 'returns true when all resources are loaded', ->
        expect(scope.loaded()).toBe(true)

      it 'returns false otherwise', ->
        EnterpriseFee.loaded = false
        expect(scope.loaded()).toBe(false)

    it "delegates suppliedVariants to Enterprise", ->
      expect(scope.suppliedVariants('enterprise_id')).toEqual('supplied variants')
      expect(Enterprise.suppliedVariants).toHaveBeenCalledWith('enterprise_id')

    it 'Delegates exchangeSelectedVariants to OrderCycle', ->
      expect(scope.exchangeSelectedVariants('exchange')).toEqual('variants selected')
      expect(OrderCycle.exchangeSelectedVariants).toHaveBeenCalledWith('exchange')

    it "delegates setExchangeVariants to OrderCycle", ->
      scope.setExchangeVariants('exchange', 'variants', 'selected')
      expect(OrderCycle.setExchangeVariants).toHaveBeenCalledWith('exchange', 'variants', 'selected')

    it 'Delegates totalVariants to Enterprise', ->
      expect(scope.enterpriseTotalVariants('enterprise')).toEqual('variants total')
      expect(Enterprise.totalVariants).toHaveBeenCalledWith('enterprise')

    it 'Delegates productSuppliedToOrderCycle to OrderCycle', ->
      expect(scope.productSuppliedToOrderCycle('product')).toEqual('product supplied')
      expect(OrderCycle.productSuppliedToOrderCycle).toHaveBeenCalledWith('product')

    it 'Delegates variantSuppliedToOrderCycle to OrderCycle', ->
      expect(scope.variantSuppliedToOrderCycle('variant')).toEqual('variant supplied')
      expect(OrderCycle.variantSuppliedToOrderCycle).toHaveBeenCalledWith('variant')

    it 'Delegates exchangeDirection to OrderCycle', ->
      expect(scope.exchangeDirection('exchange')).toEqual('exchange direction')
      expect(OrderCycle.exchangeDirection).toHaveBeenCalledWith('exchange')

    it 'Finds enterprises participating in the order cycle that have fees', ->
      scope.enterprises =
        1: {id: 1, name: 'Eaterprises'}
        2: {id: 2, name: 'Pepper Tree Place'}
        3: {id: 3, name: 'South East'}
      OrderCycle.participatingEnterpriseIds = jasmine.createSpy('participatingEnterpriseIds').and.returnValue([2])
      EnterpriseFee.enterprise_fees = [ {enterprise_id: 2} ] # Pepper Tree Place has a fee
      expect(scope.enterprisesWithFees()).toEqual([
        {id: 2, name: 'Pepper Tree Place'}
        ])

    it 'Delegates enterpriseFeesForEnterprise to EnterpriseFee', ->
      scope.enterpriseFeesForEnterprise('123')
      expect(EnterpriseFee.forEnterprise).toHaveBeenCalledWith(123)

    it 'Adds order cycle suppliers', ->
      scope.new_supplier_id = 'new supplier id'
      scope.addSupplier(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addSupplier).toHaveBeenCalledWith('new supplier id')

    it 'Adds order cycle distributors', ->
      scope.new_distributor_id = 'new distributor id'
      scope.addDistributor(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addDistributor).toHaveBeenCalledWith('new distributor id')

    it 'Removes order cycle exchanges', ->
      scope.removeExchange(event, 'exchange')
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.removeExchange).toHaveBeenCalledWith('exchange')
      expect(scope.order_cycle_form.$dirty).toEqual true

    it 'Adds coordinator fees', ->
      scope.addCoordinatorFee(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addCoordinatorFee).toHaveBeenCalled()

    it 'Removes coordinator fees', ->
      scope.removeCoordinatorFee(event, 0)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.removeCoordinatorFee).toHaveBeenCalledWith(0)
      expect(scope.order_cycle_form.$dirty).toEqual true

    it 'Adds exchange fees', ->
      scope.addExchangeFee(event)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.addExchangeFee).toHaveBeenCalled()

    it 'Removes exchange fees', ->
      scope.removeExchangeFee(event, 'exchange', 0)
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.removeExchangeFee).toHaveBeenCalledWith('exchange', 0)
      expect(scope.order_cycle_form.$dirty).toEqual true

    it 'Removes distribution of a variant', ->
      scope.removeDistributionOfVariant('variant')
      expect(OrderCycle.removeDistributionOfVariant).toHaveBeenCalledWith('variant')

    it 'Submits the order cycle via OrderCycle update', ->
      eventMock = {preventDefault: jasmine.createSpy()}
      scope.submit(eventMock,'/admin/order_cycles')
      expect(eventMock.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.update).toHaveBeenCalledWith('/admin/order_cycles', scope.order_cycle_form)


describe 'OrderCycle services', ->
  describe 'Enterprise service', ->
    $httpBackend = null
    Enterprise = null

    beforeEach ->
      module 'admin.orderCycles'
      inject ($injector, _$httpBackend_)->
        Enterprise = $injector.get('Enterprise')
        $httpBackend = _$httpBackend_
        $httpBackend.whenGET('/admin/enterprises/for_order_cycle.json').respond [
          {id: 1, name: 'One', supplied_products: [1, 2], is_primary_producer: true}
          {id: 2, name: 'Two', supplied_products: [3, 4]}
          {id: 3, name: 'Three', supplied_products: [5, 6], sells: 'any'}
          ]

    it 'loads enterprises as a hash', ->
      enterprises = Enterprise.index()
      $httpBackend.flush()
      expect(enterprises).toEqual
        1: new Enterprise.Enterprise({id: 1, name: 'One', supplied_products: [1, 2], is_primary_producer: true})
        2: new Enterprise.Enterprise({id: 2, name: 'Two', supplied_products: [3, 4]})
        3: new Enterprise.Enterprise({id: 3, name: 'Three', supplied_products: [5, 6], sells: 'any'})

    it 'reports its loadedness', ->
      expect(Enterprise.loaded).toBe(false)
      Enterprise.index()
      $httpBackend.flush()
      expect(Enterprise.loaded).toBe(true)

    it 'loads producers as an array', ->
      Enterprise.index()
      $httpBackend.flush()
      expect(Enterprise.producer_enterprises).toEqual [new Enterprise.Enterprise({id: 1, name: 'One', supplied_products: [1, 2], is_primary_producer: true})]

    it 'loads hubs as an array', ->
      Enterprise.index()
      $httpBackend.flush()
      expect(Enterprise.hub_enterprises).toEqual [new Enterprise.Enterprise({id: 3, name: 'Three', supplied_products: [5, 6], sells: 'any'})]

    it 'collates all supplied products', ->
      enterprises = Enterprise.index()
      $httpBackend.flush()
      expect(Enterprise.supplied_products).toEqual [1, 2, 3, 4, 5, 6]

    it "finds supplied variants for an enterprise", ->
      spyOn(Enterprise, 'variantsOf').and.returnValue(10)
      Enterprise.index()
      $httpBackend.flush()
      expect(Enterprise.suppliedVariants(1)).toEqual [10, 10]

    describe "finding the variants of a product", ->
      it "returns the master for products without variants", ->
        p =
          master_id: 1
          variants: []
        expect(Enterprise.variantsOf(p)).toEqual [1]

      it "returns the variant ids for products with variants", ->
        p =
          master_id: 1
          variants: [{id: 2}, {id: 3}]
        expect(Enterprise.variantsOf(p)).toEqual [2, 3]

    it 'counts total variants supplied by an enterprise', ->
      enterprise =
        supplied_products: [
          {variants: []},
          {variants: []},
          {variants: [{}, {}, {}]}
          ]

      expect(Enterprise.totalVariants(enterprise)).toEqual(5)

    it 'returns zero when enterprise is null', ->
      expect(Enterprise.totalVariants(null)).toEqual(0)

  describe 'EnterpriseFee service', ->
    $httpBackend = null
    EnterpriseFee = null

    beforeEach ->
      module 'admin.orderCycles'
      inject ($injector, _$httpBackend_)->
        EnterpriseFee = $injector.get('EnterpriseFee')
        $httpBackend = _$httpBackend_
        $httpBackend.whenGET('/admin/enterprise_fees/for_order_cycle.json').respond [
          {id: 1, name: "Yayfee", enterprise_id: 1}
          {id: 2, name: "FeeTwo", enterprise_id: 2}
          ]

    it 'loads enterprise fees', ->
      enterprise_fees = EnterpriseFee.index()
      $httpBackend.flush()
      expected_fees = [
        new EnterpriseFee.EnterpriseFee({id: 1, name: "Yayfee", enterprise_id: 1})
        new EnterpriseFee.EnterpriseFee({id: 2, name: "FeeTwo", enterprise_id: 2})
        ]
      for fee, i in enterprise_fees
        expect(fee.id).toEqual(expected_fees[i].id)

    it 'reports its loadedness', ->
      expect(EnterpriseFee.loaded).toBe(false)
      EnterpriseFee.index()
      $httpBackend.flush()
      expect(EnterpriseFee.loaded).toBe(true)

    it 'returns enterprise fees for an enterprise', ->
      all_enterprise_fees = EnterpriseFee.index()
      $httpBackend.flush()
      enterprise_fees = EnterpriseFee.forEnterprise(1)
      expect(enterprise_fees).toEqual [
        new EnterpriseFee.EnterpriseFee({id: 1, name: "Yayfee", enterprise_id: 1})
        ]


  describe 'OrderCycle service', ->
    OrderCycle = null
    $httpBackend = null
    $window = null

    beforeEach ->
      $window = {navigator: {userAgent: 'foo'}}

      module 'admin.orderCycles', ($provide)->
        $provide.value('$window', $window)
        null

      inject ($injector, _$httpBackend_)->
        OrderCycle = $injector.get('OrderCycle')
        $httpBackend = _$httpBackend_
        $httpBackend.whenGET('/admin/order_cycles/123.json').respond
          id: 123
          name: 'Test Order Cycle'
          coordinator_id: 456
          coordinator_fees: []
          exchanges: [
            {sender_id: 1, receiver_id: 456, incoming: true}
            {sender_id: 456, receiver_id: 2, incoming: false}
            ]
        $httpBackend.whenGET('/admin/order_cycles/new.json').respond
          id: 123
          name: 'New Order Cycle'
          coordinator_id: 456
          coordinator_fees: []
          exchanges: []

    it 'initialises order cycle', ->
      expect(OrderCycle.order_cycle).toEqual {incoming_exchanges: [], outgoing_exchanges: []}

    it 'counts selected variants in an exchange', ->
      result = OrderCycle.exchangeSelectedVariants({variants: {1: true, 2: false, 3: true}})
      expect(result).toEqual(2)

    describe "fetching exchange ids", ->
      it "gets enterprise ids as ints", ->
        OrderCycle.order_cycle.incoming_exchanges = [
          {enterprise_id: 1}
          {enterprise_id: '2'}
        ]
        OrderCycle.order_cycle.outgoing_exchanges = [
          {enterprise_id: 3}
          {enterprise_id: '4'}
        ]
        expect(OrderCycle.exchangeIds('incoming')).toEqual [1, 2]

    describe "checking for novel enterprises", ->
      e1 = {id: 1}
      e2 = {id: 2}

      beforeEach ->
        OrderCycle.order_cycle.incoming_exchanges = [{enterprise_id: 1}]
        OrderCycle.order_cycle.outgoing_exchanges = [{enterprise_id: 1}]

      it "detects novel suppliers", ->
        expect(OrderCycle.novelSupplier(e1)).toBe false
        expect(OrderCycle.novelSupplier(e2)).toBe true

      it "detects novel suppliers with enterprise as string id", ->
        expect(OrderCycle.novelSupplier('1')).toBe false
        expect(OrderCycle.novelSupplier('2')).toBe true

      it "detects novel distributors", ->
        expect(OrderCycle.novelDistributor(e1)).toBe false
        expect(OrderCycle.novelDistributor(e2)).toBe true

      it "detects novel distributors with enterprise as string id", ->
        expect(OrderCycle.novelDistributor('1')).toBe false
        expect(OrderCycle.novelDistributor('2')).toBe true


    describe 'fetching the direction for an exchange', ->
      it 'returns "incoming" for incoming exchanges', ->
        exchange = {id: 1}
        OrderCycle.order_cycle.incoming_exchanges = [exchange]
        OrderCycle.order_cycle.outgoing_exchanges = []
        expect(OrderCycle.exchangeDirection(exchange)).toEqual 'incoming'

      it 'returns "outgoing" for outgoing exchanges', ->
        exchange = {id: 1}
        OrderCycle.order_cycle.incoming_exchanges = []
        OrderCycle.order_cycle.outgoing_exchanges = [exchange]
        expect(OrderCycle.exchangeDirection(exchange)).toEqual 'outgoing'

    describe "setting exchange variants", ->
      describe "when I have permissions to edit the variants", ->
        beforeEach ->
          OrderCycle.order_cycle["editable_variants_for_outgoing_exchanges"] = { 1: [1, 2, 3] }

        it "sets all variants to the provided value", ->
          exchange = { enterprise_id: 1, incoming: false, variants: {2: false}}
          OrderCycle.setExchangeVariants(exchange, [1, 2, 3], true)
          expect(exchange.variants).toEqual {1: true, 2: true, 3: true}

      describe "when I don't have permissions to edit the variants", ->
        beforeEach ->
          OrderCycle.order_cycle["editable_variants_for_outgoing_exchanges"] = { 1: [] }

        it "does not change variants to the provided value", ->
          exchange = { enterprise_id: 1, incoming: false, variants: {2: false}}
          OrderCycle.setExchangeVariants(exchange, [1, 2, 3], true)
          expect(exchange.variants).toEqual {2: false}

    describe 'adding suppliers', ->
      exchange = null

      beforeEach ->
        # Initialise OC
        OrderCycle.new()
        $httpBackend.flush()

      it 'adds the supplier to incoming exchanges', ->
        OrderCycle.addSupplier('123')
        expect(OrderCycle.order_cycle.incoming_exchanges).toEqual [
          {enterprise_id: '123', incoming: true, active: true, variants: {}, enterprise_fees: []}
        ]

    describe 'adding distributors', ->
      exchange = null

      beforeEach ->
        # Initialise OC
        OrderCycle.new()
        $httpBackend.flush()

      it 'adds the distributor to outgoing exchanges', ->
        OrderCycle.addDistributor('123')
        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
          {enterprise_id: '123', incoming: false, active: true, variants: {}, enterprise_fees: []}
        ]

    describe 'removing exchanges', ->
      exchange = null

      beforeEach ->
        spyOn(OrderCycle, 'removeDistributionOfVariant')
        exchange =
          enterprise_id: '123'
          active: true
          incoming: false
          variants: {1: true, 2: false, 3: true}
          enterprise_fees: []

      describe "removing incoming exchanges", ->
        beforeEach ->
          exchange.incoming = true
          OrderCycle.order_cycle.incoming_exchanges = [exchange]

        it 'removes the exchange', ->
          OrderCycle.removeExchange(exchange)
          expect(OrderCycle.order_cycle.incoming_exchanges).toEqual []

        it 'removes distribution of all exchange variants', ->
          OrderCycle.removeExchange(exchange)
          expect(OrderCycle.removeDistributionOfVariant).toHaveBeenCalledWith('1')
          expect(OrderCycle.removeDistributionOfVariant).not.toHaveBeenCalledWith('2')
          expect(OrderCycle.removeDistributionOfVariant).toHaveBeenCalledWith('3')

      describe "removing outgoing exchanges", ->
        beforeEach ->
          exchange.incoming = false
          OrderCycle.order_cycle.outgoing_exchanges = [exchange]

        it 'removes the exchange', ->
          OrderCycle.removeExchange(exchange)
          expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual []

        it "does not remove distribution of any variants", ->
          OrderCycle.removeExchange(exchange)
          expect(OrderCycle.removeDistributionOfVariant).not.toHaveBeenCalled()

    it 'adds coordinator fees', ->
      # Initialise OC
      OrderCycle.new()
      $httpBackend.flush()
      OrderCycle.addCoordinatorFee()
      expect(OrderCycle.order_cycle.coordinator_fees).toEqual [{}]

    describe 'removing coordinator fees', ->
      it 'removes a coordinator fee by index', ->
        OrderCycle.order_cycle.coordinator_fees = [
          {id: 1}
          {id: 2}
          {id: 3}
          ]
        OrderCycle.removeCoordinatorFee(1)
        expect(OrderCycle.order_cycle.coordinator_fees).toEqual [
          {id: 1}
          {id: 3}
          ]

    it 'adds exchange fees', ->
      exchange = {enterprise_fees: []}
      OrderCycle.addExchangeFee(exchange)
      expect(exchange.enterprise_fees).toEqual [{}]

    describe 'removing exchange fees', ->
      it 'removes an exchange fee by index', ->
        exchange =
          enterprise_fees: [
            {id: 1}
            {id: 2}
            {id: 3}
            ]
        OrderCycle.removeExchangeFee(exchange, 1)
        expect(exchange.enterprise_fees).toEqual [
          {id: 1}
          {id: 3}
          ]

    it 'finds participating enterprise ids', ->
      OrderCycle.order_cycle.incoming_exchanges = [
        {enterprise_id: 1}
        {enterprise_id: 2}
      ]
      OrderCycle.order_cycle.outgoing_exchanges = [
        {enterprise_id: 2}
        {enterprise_id: 3}
      ]
      expect(OrderCycle.participatingEnterpriseIds()).toEqual [1, 2, 3]

    describe 'fetching all variants supplied on incoming exchanges', ->
      it 'collects variants from incoming exchanges', ->
        OrderCycle.order_cycle.incoming_exchanges = [
          {variants: {1: true, 2: false}}
          {variants: {3: false, 4: true}}
          {variants: {5: true, 6: false}}
        ]
        expect(OrderCycle.incomingExchangesVariants()).toEqual [1, 4, 5]

    describe 'checking whether a product is supplied to the order cycle', ->
      product_master_present = product_variant_present = product_master_absent = product_variant_absent = null

      beforeEach ->
        product_master_present =
          name: "Linseed (500g)"
          master_id: 1
          variants: []
        product_variant_present =
          name: "Linseed (500g)"
          master_id: 2
          variants: [{id: 3}, {id: 4}]
        product_master_absent =
          name: "Linseed (500g)"
          master_id: 5
          variants: []
        product_variant_absent =
          name: "Linseed (500g)"
          master_id: 6
          variants: [{id: 7}, {id: 8}]

        spyOn(OrderCycle, 'incomingExchangesVariants').and.returnValue([1, 3])

      it 'returns true for products whose master is supplied', ->
        expect(OrderCycle.productSuppliedToOrderCycle(product_master_present)).toBeTruthy()

      it 'returns true for products for whom a variant is supplied', ->
        expect(OrderCycle.productSuppliedToOrderCycle(product_variant_present)).toBeTruthy()

      it 'returns false for products whose master is not supplied', ->
        expect(OrderCycle.productSuppliedToOrderCycle(product_master_absent)).toBeFalsy()

      it 'returns false for products whose variants are not supplied', ->
        expect(OrderCycle.productSuppliedToOrderCycle(product_variant_absent)).toBeFalsy()


    describe 'checking whether a variant is supplied to the order cycle', ->
      beforeEach ->
        spyOn(OrderCycle, 'incomingExchangesVariants').and.returnValue([1, 3])

      it 'returns true for variants that are supplied', ->
        expect(OrderCycle.variantSuppliedToOrderCycle({id: 1})).toBeTruthy()

      it 'returns false for variants that are not supplied', ->
        expect(OrderCycle.variantSuppliedToOrderCycle({id: 999})).toBeFalsy()


    describe 'remove all distribution of a variant', ->
      it 'removes the variant from every outgoing exchange', ->
        OrderCycle.order_cycle.outgoing_exchanges = [
          {variants: {123: true, 234: true}}
          {variants: {123: true, 333: true}}
        ]
        OrderCycle.removeDistributionOfVariant('123')
        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
          {variants: {123: false, 234: true}}
          {variants: {123: false, 333: true}}
        ]

    describe 'loading an order cycle, reporting loadedness', ->
      it 'reports its loadedness', ->
        expect(OrderCycle.loaded).toBe(false)
        OrderCycle.load('123')
        $httpBackend.flush()
        expect(OrderCycle.loaded).toBe(true)

    describe 'loading a new order cycle', ->
      beforeEach ->
        OrderCycle.new()
        $httpBackend.flush()


      it 'loads basic fields', ->
        expect(OrderCycle.order_cycle.id).toEqual(123)
        expect(OrderCycle.order_cycle.name).toEqual('New Order Cycle')
        expect(OrderCycle.order_cycle.coordinator_id).toEqual(456)

      it 'initialises the incoming and outgoing exchanges', ->
        expect(OrderCycle.order_cycle.incoming_exchanges).toEqual []
        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual []

      it 'removes the original exchanges array', ->
        expect(OrderCycle.order_cycle.exchanges).toBeUndefined()

    describe 'loading an existing order cycle', ->
      beforeEach ->
        OrderCycle.load('123')
        $httpBackend.flush()

      it 'loads basic fields', ->
        expect(OrderCycle.order_cycle.id).toEqual(123)
        expect(OrderCycle.order_cycle.name).toEqual('Test Order Cycle')
        expect(OrderCycle.order_cycle.coordinator_id).toEqual(456)

      it 'splits exchanges into incoming and outgoing', ->
        expect(OrderCycle.order_cycle.incoming_exchanges).toEqual [
          sender_id: 1
          enterprise_id: 1
          incoming: true
          active: true
          ]

        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
          receiver_id: 2
          enterprise_id: 2
          incoming: false
          active: true
          ]

      it 'removes the original exchanges array', ->
        expect(OrderCycle.order_cycle.exchanges).toBeUndefined()

    describe 'creating an order cycle', ->
      beforeEach ->
        spyOn(OrderCycle, 'confirmNoDistributors').and.returnValue true

      it 'redirects to the destination page on success', ->
        OrderCycle.order_cycle = 'this is the order cycle'
        spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
        $httpBackend.expectPOST('/admin/order_cycles.json', {
          order_cycle: 'this is the submit data'
          }).respond {success: true}

        OrderCycle.create('/destination/page')
        $httpBackend.flush()
        expect($window.location).toEqual('/destination/page')

      it 'does not redirect on error', ->
        OrderCycle.order_cycle = 'this is the order cycle'
        spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
        $httpBackend.expectPOST('/admin/order_cycles.json', {
          order_cycle: 'this is the submit data'
          }).respond {success: false}

        OrderCycle.create('/destination/page')
        $httpBackend.flush()
        expect($window.location).toEqual(undefined)

    describe 'updating an order cycle', ->
      beforeEach ->
        spyOn(OrderCycle, 'confirmNoDistributors').and.returnValue true

      it 'redirects to the destination page on success', ->
        form = jasmine.createSpyObj('order_cycle_form', ['$dirty', '$setPristine'])
        OrderCycle.order_cycle = 'this is the order cycle'
        spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
        $httpBackend.expectPUT('/admin/order_cycles.json?reloading=1', {
          order_cycle: 'this is the submit data'
          }).respond {success: true}

        OrderCycle.update('/destination/page', form)
        $httpBackend.flush()
        expect($window.location).toEqual('/destination/page')
        expect(form.$setPristine.calls.count()).toBe 1

      it 'does not redirect on error', ->
        OrderCycle.order_cycle = 'this is the order cycle'
        spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
        $httpBackend.expectPUT('/admin/order_cycles.json?reloading=1', {
          order_cycle: 'this is the submit data'
          }).respond {success: false}

        OrderCycle.update('/destination/page')
        $httpBackend.flush()
        expect($window.location).toEqual(undefined)

    describe 'preparing data for form submission', ->
      it 'calls all the methods', ->
        OrderCycle.order_cycle = {foo: 'bar'}
        spyOn(OrderCycle, 'removeInactiveExchanges')
        spyOn(OrderCycle, 'translateCoordinatorFees')
        spyOn(OrderCycle, 'translateExchangeFees')
        OrderCycle.dataForSubmit()
        expect(OrderCycle.removeInactiveExchanges).toHaveBeenCalled()
        expect(OrderCycle.translateCoordinatorFees).toHaveBeenCalled()
        expect(OrderCycle.translateExchangeFees).toHaveBeenCalled()

      it 'removes inactive exchanges', ->
        data =
          incoming_exchanges: [
            {enterprise_id: "1", active: false}
            {enterprise_id: "2", active: true}
            {enterprise_id: "3", active: false}
            ]
          outgoing_exchanges: [
            {enterprise_id: "4", active: true}
            {enterprise_id: "5", active: false}
            {enterprise_id: "6", active: true}
            ]

        data = OrderCycle.removeInactiveExchanges(data)

        expect(data.incoming_exchanges).toEqual [
          {enterprise_id: "2", active: true}
          ]
        expect(data.outgoing_exchanges).toEqual [
          {enterprise_id: "4", active: true}
          {enterprise_id: "6", active: true}
          ]

      it 'converts coordinator fees into a list of ids', ->
        order_cycle =
          coordinator_fees: [
            {id: 1}
            {id: 2}
            ]

        data = OrderCycle.translateCoordinatorFees(order_cycle)

        expect(data.coordinator_fees).toBeUndefined()
        expect(data.coordinator_fee_ids).toEqual [1, 2]

      it "preserves original data when converting coordinator fees", ->
       OrderCycle.order_cycle =
          coordinator_fees: [
            {id: 1}
            {id: 2}
            ]

        data = OrderCycle.deepCopy()
        data = OrderCycle.translateCoordinatorFees(data)

        expect(OrderCycle.order_cycle.coordinator_fees).toEqual [{id: 1}, {id: 2}]
        expect(OrderCycle.order_cycle.coordinator_fee_ids).toBeUndefined()

      describe "converting exchange fees into a list of ids", ->
        order_cycle = null
        data = null

        beforeEach ->
          order_cycle =
            incoming_exchanges: [
              enterprise_fees: [
                {id: 1}
                {id: 2}
              ]
            ]
            outgoing_exchanges: [
              enterprise_fees: [
                {id: 3}
                {id: 4}
              ]
            ]
          OrderCycle.order_cycle = order_cycle

          data = OrderCycle.deepCopy()
          data = OrderCycle.translateExchangeFees(data)

        it 'converts exchange fees into a list of ids', ->
          expect(data.incoming_exchanges[0].enterprise_fees).toBeUndefined()
          expect(data.outgoing_exchanges[0].enterprise_fees).toBeUndefined()
          expect(data.incoming_exchanges[0].enterprise_fee_ids).toEqual [1, 2]
          expect(data.outgoing_exchanges[0].enterprise_fee_ids).toEqual [3, 4]

        it "preserves original data when converting exchange fees", ->
          expect(order_cycle.incoming_exchanges[0].enterprise_fees).toEqual [{id: 1}, {id: 2}]
          expect(order_cycle.outgoing_exchanges[0].enterprise_fees).toEqual [{id: 3}, {id: 4}]
          expect(order_cycle.incoming_exchanges[0].enterprise_fee_ids).toBeUndefined()
          expect(order_cycle.outgoing_exchanges[0].enterprise_fee_ids).toBeUndefined()

    describe "confirming when there are no distributors", ->
      order_cycle_with_exchanges = order_cycle_without_exchanges = null

      beforeEach ->
        order_cycle_with_exchanges =
          outgoing_exchanges: [{}]
        order_cycle_without_exchanges =
          outgoing_exchanges: []

      it "returns true when there are distributors", ->
        spyOn(window, 'confirm')
        OrderCycle.order_cycle = order_cycle_with_exchanges
        expect(OrderCycle.confirmNoDistributors()).toBe true
        expect(window.confirm).not.toHaveBeenCalled()

      it "returns true when there are no distributors but the user confirms", ->
        spyOn(window, 'confirm').and.returnValue(true)
        OrderCycle.order_cycle = order_cycle_without_exchanges
        expect(OrderCycle.confirmNoDistributors()).toBe true
        expect(window.confirm).toHaveBeenCalled()

      it "returns false when there are no distributors and the user does not confirm", ->
        spyOn(window, 'confirm').and.returnValue(false)
        OrderCycle.order_cycle = order_cycle_without_exchanges
        expect(OrderCycle.confirmNoDistributors()).toBe false
        expect(window.confirm).toHaveBeenCalled()
