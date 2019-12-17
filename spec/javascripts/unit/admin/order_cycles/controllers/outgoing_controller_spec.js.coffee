describe 'AdminOrderCycleOutgoingCtrl', ->
  ctrl = null
  scope = null
  event = null
  location = null
  OrderCycle = null
  Enterprise = null
  EnterpriseFee = null

  beforeEach ->
    scope =
      $watch: jasmine.createSpy('$watch')
    location =
      absUrl: ->
        'example.com/admin/order_cycles/27/edit'
    event =
      preventDefault: jasmine.createSpy('preventDefault')
    OrderCycle =
      variantSuppliedToOrderCycle: jasmine.createSpy('variantSuppliedToOrderCycle').and.returnValue('variant supplied')
      addDistributor: jasmine.createSpy('addDistributor')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleOutgoingCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'Delegates variantSuppliedToOrderCycle to OrderCycle', ->
    expect(scope.variantSuppliedToOrderCycle('variant')).toEqual('variant supplied')
    expect(OrderCycle.variantSuppliedToOrderCycle).toHaveBeenCalledWith('variant')

  it 'Adds order cycle distributors', ->
    scope.new_distributor_id = 'new distributor id'

    scope.addDistributor(event)

    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.addDistributor).toHaveBeenCalledWith('new distributor id')
