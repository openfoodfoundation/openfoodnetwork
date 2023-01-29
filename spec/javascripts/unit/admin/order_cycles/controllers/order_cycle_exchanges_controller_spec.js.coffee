describe 'AdminOrderCycleExchangesCtrl', ->
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
      order_cycle:
        coordinator_id: 4
      exchangeSelectedVariants: jasmine.createSpy('exchangeSelectedVariants').and.returnValue('variants selected')
      exchangeDirection: jasmine.createSpy('exchangeDirection').and.returnValue('exchange direction')
      removeExchange: jasmine.createSpy('removeExchange')
      addExchangeFee: jasmine.createSpy('addExchangeFee')
      removeExchangeFee: jasmine.createSpy('removeExchangeFee')
      removeDistributionOfVariant: jasmine.createSpy('removeDistributionOfVariant')
    Enterprise = {}
    EnterpriseFee =
      forEnterprise: jasmine.createSpy('forEnterprise').and.returnValue('enterprise fees for enterprise')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleExchangesCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'Delegates exchangeSelectedVariants to OrderCycle', ->
    expect(scope.exchangeSelectedVariants('exchange')).toEqual('variants selected')
    expect(OrderCycle.exchangeSelectedVariants).toHaveBeenCalledWith('exchange')

  it 'Delegates exchangeDirection to OrderCycle', ->
    expect(scope.exchangeDirection('exchange')).toEqual('exchange direction')
    expect(OrderCycle.exchangeDirection).toHaveBeenCalledWith('exchange')

  it 'Finds enterprises participating in the order cycle that have fees', ->
    # this is inhetited from order_cycle_basic_controller
    scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))
    scope.enterprises =
      1: {id: 1, name: 'Eaterprises'}
      2: {id: 2, name: 'Pepper Tree Place'}
      3: {id: 3, name: 'South East'}
      4: {id: 4, name: 'coordinator'}
    OrderCycle.participatingEnterpriseIds = jasmine.createSpy('participatingEnterpriseIds').and.returnValue([2])
    EnterpriseFee.enterprise_fees = [ {enterprise_id: 2} ] # Pepper Tree Place has a fee
    expect(scope.enterprisesWithFees()).toEqual([
      {id: 2, name: 'Pepper Tree Place'},
      {id: 4, name: 'coordinator'}
      ])
  
  it 'Finds unique enterprises participating in the order cycle that have fees', ->
    scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))
    scope.enterprises = 
      1: {id: 1, name: 'Eaterprises'}
      2: {id: 2, name: 'Pepper Tree Place'}
      3: {id: 3, name: 'South East'}
      4: {id: 4, name: 'coordinator'}
    OrderCycle.participatingEnterpriseIds = jasmine.createSpy('participatingEnterpriseIds').and.returnValue([2, 2])
    EnterpriseFee.enterprise_fees = [ {enterprise_id: 2} ]
    expect(scope.enterprisesWithFees()).toEqual([
      {id: 2, name: 'Pepper Tree Place'},
      {id: 4, name: 'coordinator'}
      ])

  it 'Removes order cycle exchanges', ->
    scope.removeExchange(event, 'exchange')
    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.removeExchange).toHaveBeenCalledWith('exchange')
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

