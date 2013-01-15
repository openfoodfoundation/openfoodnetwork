describe 'OrderCycle controllers', ->

  describe 'AdminCreateOrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    OrderCycle = null
    Enterprise = null

    beforeEach ->
      scope = {}
      event =
        preventDefault: jasmine.createSpy('preventDefault')
      OrderCycle =
        order_cycle: 'my order cycle'
        exchangeSelectedVariants: jasmine.createSpy('exchangeSelectedVariants').andReturn('variants selected')
        toggleProducts: jasmine.createSpy('toggleProducts')
        addSupplier: jasmine.createSpy('addSupplier')
        addDistributor: jasmine.createSpy('addDistributor')
        create: jasmine.createSpy('create')
      Enterprise =
        index: jasmine.createSpy('index').andReturn('enterprises list')
        supplied_products: 'supplied products'
        totalVariants: jasmine.createSpy('totalVariants').andReturn('variants total')

      module('order_cycle')
      inject ($controller) ->
        ctrl = $controller 'AdminCreateOrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle, Enterprise: Enterprise}


    it 'Loads enterprises and supplied products', ->
      expect(Enterprise.index).toHaveBeenCalled()
      expect(scope.enterprises).toEqual('enterprises list')
      expect(scope.supplied_products).toEqual('supplied products')

    it 'Loads order cycles', ->
      expect(scope.order_cycle).toEqual('my order cycle')

    it 'Delegates exchangeSelectedVariants to OrderCycle', ->
      expect(scope.exchangeSelectedVariants('exchange')).toEqual('variants selected')
      expect(OrderCycle.exchangeSelectedVariants).toHaveBeenCalledWith('exchange')

    it 'Delegates enterpriseTotalVariants to Enterprise', ->
      expect(scope.enterpriseTotalVariants('enterprise')).toEqual('variants total')
      expect(Enterprise.totalVariants).toHaveBeenCalledWith('enterprise')

    it 'Delegates toggleProducts to OrderCycle', ->
      scope.toggleProducts(event, 'exchange')
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.toggleProducts).toHaveBeenCalledWith('exchange')

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

    it 'Submits the order cycle via OrderCycle create', ->
      scope.submit()
      expect(OrderCycle.create).toHaveBeenCalled()

  describe 'AdminEditOrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    location = null
    OrderCycle = null
    Enterprise = null

    beforeEach ->
      scope = {}
      event =
        preventDefault: jasmine.createSpy('preventDefault')
      location =
        absUrl: ->
          'example.com/admin/order_cycles/27/edit'
      OrderCycle =
        load: jasmine.createSpy('load')
        exchangeSelectedVariants: jasmine.createSpy('exchangeSelectedVariants').andReturn('variants selected')
        toggleProducts: jasmine.createSpy('toggleProducts')
        addSupplier: jasmine.createSpy('addSupplier')
        addDistributor: jasmine.createSpy('addDistributor')
        update: jasmine.createSpy('update')
      Enterprise =
        index: jasmine.createSpy('index').andReturn('enterprises list')
        supplied_products: 'supplied products'
        totalVariants: jasmine.createSpy('totalVariants').andReturn('variants total')

      module('order_cycle')
      inject ($controller) ->
        ctrl = $controller 'AdminEditOrderCycleCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise}

    it 'Loads enterprises and supplied products', ->
      expect(Enterprise.index).toHaveBeenCalled()
      expect(scope.enterprises).toEqual('enterprises list')
      expect(scope.supplied_products).toEqual('supplied products')

    it 'Loads order cycles', ->
      expect(OrderCycle.load).toHaveBeenCalledWith('27')

    it 'Delegates exchangeSelectedVariants to OrderCycle', ->
      expect(scope.exchangeSelectedVariants('exchange')).toEqual('variants selected')
      expect(OrderCycle.exchangeSelectedVariants).toHaveBeenCalledWith('exchange')

    it 'Delegates totalVariants to Enterprise', ->
      expect(scope.enterpriseTotalVariants('enterprise')).toEqual('variants total')
      expect(Enterprise.totalVariants).toHaveBeenCalledWith('enterprise')

    it 'Delegates toggleProducts to OrderCycle', ->
      scope.toggleProducts(event, 'exchange')
      expect(event.preventDefault).toHaveBeenCalled()
      expect(OrderCycle.toggleProducts).toHaveBeenCalledWith('exchange')

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

    it 'Submits the order cycle via OrderCycle update', ->
      scope.submit()
      expect(OrderCycle.update).toHaveBeenCalled()


describe 'OrderCycle services', ->
  describe 'Enterprise service', ->
    $httpBackend = null
    Enterprise = null

    beforeEach ->
      module 'order_cycle'
      inject ($injector, _$httpBackend_)->
        Enterprise = $injector.get('Enterprise')
        $httpBackend = _$httpBackend_
        $httpBackend.whenGET('/admin/enterprises.json').respond [
          {id: 1, name: 'One', supplied_products: [1, 2]}
          {id: 2, name: 'Two', supplied_products: [3, 4]}
          {id: 3, name: 'Three', supplied_products: [5, 6]}
          ]

    it 'loads enterprises as a hash', ->
      enterprises = Enterprise.index()
      $httpBackend.flush()
      expect(enterprises).toEqual
        1: new Enterprise.Enterprise({id: 1, name: 'One', supplied_products: [1, 2]})
        2: new Enterprise.Enterprise({id: 2, name: 'Two', supplied_products: [3, 4]})
        3: new Enterprise.Enterprise({id: 3, name: 'Three', supplied_products: [5, 6]})

    it 'collates all supplied products', ->
      enterprises = Enterprise.index()
      $httpBackend.flush()
      expect(Enterprise.supplied_products).toEqual [1, 2, 3, 4, 5, 6]

    it 'counts total variants supplied by an enterprise', ->
      enterprise =
        supplied_products: [
          {variants: []},
          {variants: []},
          {variants: [{}, {}, {}]}
          ]

      expect(Enterprise.totalVariants(enterprise)).toEqual(5)


  describe 'OrderCycle service', ->
    OrderCycle = null
    $httpBackend = null
    $window = null

    beforeEach ->
      $window = {navigator: {userAgent: 'foo'}}

      module 'order_cycle', ($provide)->
        $provide.value('$window', $window)
        null

      inject ($injector, _$httpBackend_)->
        OrderCycle = $injector.get('OrderCycle')
        $httpBackend = _$httpBackend_
        $httpBackend.whenGET('/admin/order_cycles/123.json').respond
          id: 123
          name: 'Test Order Cycle'
          coordinator_id: 456
          exchanges: [
            {sender_id: 1, receiver_id: 456}
            {sender_id: 456, receiver_id: 2}
            ]

    it 'initialises order cycle', ->
      expect(OrderCycle.order_cycle).toEqual
        incoming_exchanges: []
        outgoing_exchanges: []

    it 'counts selected variants in an exchange', ->
      result = OrderCycle.exchangeSelectedVariants({variants: {1: true, 2: false, 3: true}})
      expect(result).toEqual(2)

    describe 'toggling products', ->
      exchange = null

      beforeEach ->
        exchange = {}

      it 'sets a blank value to true', ->
        OrderCycle.toggleProducts(exchange)
        expect(exchange.showProducts).toEqual(true)

      it 'sets a true value to false', ->
        exchange.showProducts = true
        OrderCycle.toggleProducts(exchange)
        expect(exchange.showProducts).toEqual(false)

      it 'sets a false value to true', ->
        exchange.showProducts = false
        OrderCycle.toggleProducts(exchange)
        expect(exchange.showProducts).toEqual(true)

    describe 'adding suppliers', ->
      exchange = null

      it 'adds the supplier to incoming exchanges', ->
        OrderCycle.addSupplier('123')
        expect(OrderCycle.order_cycle.incoming_exchanges).toEqual [
          {enterprise_id: '123', active: true, variants: {}}
        ]

    describe 'adding distributors', ->
      exchange = null

      it 'adds the distributor to outgoing exchanges', ->
        OrderCycle.addDistributor('123')
        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
          {enterprise_id: '123', active: true, variants: {}}
        ]

    describe 'loading an order cycle', ->
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
          active: true
          ]

        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
          receiver_id: 2
          enterprise_id: 2
          active: true
          ]

      it 'removes original exchanges array', ->
        expect(OrderCycle.order_cycle.exchanges).toEqual(undefined)

    describe 'creating an order cycle', ->
      it 'redirects to the order cycles page on success', ->
        OrderCycle.order_cycle = 'this is the order cycle'
        spyOn(OrderCycle, 'removeInactiveExchanges')
        $httpBackend.expectPOST('/admin/order_cycles.json', {
          order_cycle: 'this is the order cycle'
          }).respond {success: true}

        OrderCycle.create()
        $httpBackend.flush()
        expect(OrderCycle.removeInactiveExchanges).toHaveBeenCalled()
        expect($window.location).toEqual('/admin/order_cycles')

      it 'does not redirect on error', ->
        OrderCycle.order_cycle = 'this is the order cycle'
        spyOn(OrderCycle, 'removeInactiveExchanges')
        $httpBackend.expectPOST('/admin/order_cycles.json', {
          order_cycle: 'this is the order cycle'
          }).respond {success: false}

        OrderCycle.create()
        $httpBackend.flush()
        expect(OrderCycle.removeInactiveExchanges).toHaveBeenCalled()
        expect($window.location).toEqual(undefined)

      it 'removes inactive exchanges', ->
        OrderCycle.order_cycle =
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
        OrderCycle.removeInactiveExchanges()
        expect(OrderCycle.order_cycle.incoming_exchanges).toEqual [
          {enterprise_id: "2", active: true}
          ]
        expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
          {enterprise_id: "4", active: true}
          {enterprise_id: "6", active: true}
          ]
