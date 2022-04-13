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
    $httpBackend = null
    Enterprise = null

    beforeEach ->
      # Initialise OC
      OrderCycle.new()
      inject ($injector, _$httpBackend_)->
        Enterprise = $injector.get('Enterprise')
        $httpBackend = _$httpBackend_
        $httpBackend.whenGET('/admin/enterprises/for_order_cycle.json').respond [
          {id: 1, name: 'Three', sells: 'any'}
        ]

    it 'adds the distributor to outgoing exchanges', ->
      $httpBackend.flush()
      OrderCycle.addDistributor('123')
      expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
        {enterprise_id: '123', incoming: false, active: true, variants: {}, enterprise_fees: []}
      ]

    it 'selects all variants if only one distributor', ->
      Enterprise.index()
      $httpBackend.flush()
      OrderCycle.order_cycle.editable_variants_for_outgoing_exchanges = {
        123: [123, 234, 456, 789]
      }
      OrderCycle.order_cycle.incoming_exchanges = [
        {variants: {123: true, 234: true}}
        {variants: {456: true, 789: false}}
      ]
      OrderCycle.addDistributor('123')
      expect(OrderCycle.order_cycle.outgoing_exchanges).toEqual [
        {enterprise_id: '123', incoming: false, active: true, variants: {123: true, 234: true, 456: true}, enterprise_fees: []}
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

    it 'redirects to the given destination on success', ->
      OrderCycle.order_cycle = 'this is the order cycle'
      spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
      $httpBackend.expectPOST('/admin/order_cycles.json', {
        order_cycle: 'this is the submit data'
        }).respond {success: true, edit_path: "/edit/path"}

      OrderCycle.create('/destination/page')
      $httpBackend.flush()
      expect($window.location).toEqual('/destination/page')

    it 'redirects to the edit_path on success if no destination is given', ->
      OrderCycle.order_cycle = 'this is the order cycle'
      spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
      $httpBackend.expectPOST('/admin/order_cycles.json', {
        order_cycle: 'this is the submit data'
        }).respond {success: true, edit_path: "/edit/path"}

      OrderCycle.create()
      $httpBackend.flush()
      expect($window.location).toEqual('/edit/path')

    it 'does not redirect on error', ->
      OrderCycle.order_cycle = 'this is the order cycle'
      spyOn(OrderCycle, 'dataForSubmit').and.returnValue('this is the submit data')
      $httpBackend.expectPOST('/admin/order_cycles.json', {
        order_cycle: 'this is the submit data'
      }).respond 400, { errors: [] }

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
      }).respond 400, { errors: [] }

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
