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
    OrderCycle =
      productSuppliedToOrderCycle: jasmine.createSpy('productSuppliedToOrderCycle').and.returnValue('product supplied')
      variantSuppliedToOrderCycle: jasmine.createSpy('variantSuppliedToOrderCycle').and.returnValue('variant supplied')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleOutgoingCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'Delegates productSuppliedToOrderCycle to OrderCycle', ->
    expect(scope.productSuppliedToOrderCycle('product')).toEqual('product supplied')
    expect(OrderCycle.productSuppliedToOrderCycle).toHaveBeenCalledWith('product')

  it 'Delegates variantSuppliedToOrderCycle to OrderCycle', ->
    expect(scope.variantSuppliedToOrderCycle('variant')).toEqual('variant supplied')
    expect(OrderCycle.variantSuppliedToOrderCycle).toHaveBeenCalledWith('variant')
