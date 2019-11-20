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
    Enterprise =
      totalVariants: jasmine.createSpy('totalVariants').and.returnValue('variants total')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminOrderCycleIncomingCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'Delegates totalVariants to Enterprise', ->
    expect(scope.enterpriseTotalVariants('enterprise')).toEqual('variants total')
    expect(Enterprise.totalVariants).toHaveBeenCalledWith('enterprise')
