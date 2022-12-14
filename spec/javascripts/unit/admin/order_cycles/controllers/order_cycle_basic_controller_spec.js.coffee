describe 'AdminOrderCycleBasicCtrl', ->
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
    OrderCycle =
      setExchangeVariants: jasmine.createSpy('setExchangeVariants')
      addCoordinatorFee: jasmine.createSpy('addCoordinatorFee')
      removeCoordinatorFee: jasmine.createSpy('removeCoordinatorFee')
    Enterprise =
      suppliedVariants: jasmine.createSpy('suppliedVariants').and.returnValue('supplied variants')
    EnterpriseFee =
      forEnterprise: jasmine.createSpy('forEnterprise').and.returnValue('enterprise fees for enterprise')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleBasicCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

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

  it "delegates setExchangeVariants to OrderCycle", ->
    scope.setExchangeVariants('exchange', 'variants', 'selected')
    expect(OrderCycle.setExchangeVariants).toHaveBeenCalledWith('exchange', 'variants', 'selected')

  it 'Delegates enterpriseFeesForEnterprise to EnterpriseFee', ->
    scope.enterpriseFeesForEnterprise('123')
    expect(EnterpriseFee.forEnterprise).toHaveBeenCalledWith(123)

  it 'Adds coordinator fees', ->
    scope.addCoordinatorFee(event)
    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.addCoordinatorFee).toHaveBeenCalled()

  it 'Removes coordinator fees', ->
    scope.removeCoordinatorFee(event, 0)
    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.removeCoordinatorFee).toHaveBeenCalledWith(0)
