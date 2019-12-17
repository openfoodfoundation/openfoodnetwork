describe 'AdminOrderCycleIncomingCtrl', ->
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
      addSupplier: jasmine.createSpy('addSupplier')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleIncomingCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'adds order cycle suppliers', ->
    scope.new_supplier_id = 'new supplier id'

    scope.addSupplier(event)

    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.addSupplier).toHaveBeenCalledWith('new supplier id')
