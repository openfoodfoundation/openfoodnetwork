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
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminEditOrderCycleCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

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
