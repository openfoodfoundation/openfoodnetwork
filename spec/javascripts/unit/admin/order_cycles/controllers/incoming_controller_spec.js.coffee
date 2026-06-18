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
    EnterpriseFee =
      loading: false
      index: jasmine.createSpy('index').and.returnValue('enterprise fees list')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleIncomingCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'adds order cycle suppliers', ->
    scope.new_supplier_id = 'new supplier id'

    scope.addSupplier(event)

    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.addSupplier).toHaveBeenCalledWith('new supplier id')

  it 'lists only incoming fees from the loaded incoming fee list', ->
    scope.enterprise_fees = [
      { enterprise_id: 1, name: 'fee 1' }
      { enterprise_id: 2, name: 'fee 2' }
    ]

    expect(scope.enterpriseFeesForEnterprise(1)).toEqual [{ enterprise_id: 1, name: 'fee 1' }]
