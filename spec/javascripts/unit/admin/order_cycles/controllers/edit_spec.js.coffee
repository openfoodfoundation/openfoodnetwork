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
      removeCoordinatorFee: jasmine.createSpy('removeCoordinatorFee')
      update: jasmine.createSpy('update')
    Enterprise =
      index: jasmine.createSpy('index').and.returnValue('enterprises list')
    EnterpriseFee =
      index: jasmine.createSpy('index').and.returnValue('enterprise fees list')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminEditOrderCycleCtrl', {$scope: scope, $location: location, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'Loads enterprises and supplied products', ->
    expect(Enterprise.index).toHaveBeenCalled()
    expect(scope.enterprises).toEqual('enterprises list')

  it 'Loads enterprise fees', ->
    expect(EnterpriseFee.index).toHaveBeenCalled()
    expect(scope.enterprise_fees).toEqual('enterprise fees list')

  it 'Removes coordinator fees', ->
    scope.removeCoordinatorFee(event, 0)
    expect(event.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.removeCoordinatorFee).toHaveBeenCalledWith(0)
    expect(scope.order_cycle_form.$dirty).toEqual true

  it 'Submits the order cycle via OrderCycle update', ->
    eventMock = {preventDefault: jasmine.createSpy()}
    scope.submit(eventMock,'/admin/order_cycles')
    expect(eventMock.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.update).toHaveBeenCalledWith('/admin/order_cycles', scope.order_cycle_form)
