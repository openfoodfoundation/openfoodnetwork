describe 'AdminCreateOrderCycleCtrl', ->
  ctrl = null
  scope = null
  event = null
  OrderCycle = null
  Enterprise = null
  EnterpriseFee = null

  beforeEach ->
    scope =
      $watch: jasmine.createSpy('$watch')
    OrderCycle =
      create: jasmine.createSpy('create')
      new: jasmine.createSpy('new').and.returnValue "my order cycle"
    Enterprise =
      index: jasmine.createSpy('index').and.returnValue('enterprises list')
    EnterpriseFee =
      index: jasmine.createSpy('index').and.returnValue('enterprise fees list')
    ocInstance = {}

    module('admin.orderCycles')
    inject ($controller) ->
      ctrl = $controller 'AdminCreateOrderCycleCtrl', {$scope: scope, OrderCycle: OrderCycle, Enterprise: Enterprise, EnterpriseFee: EnterpriseFee, ocInstance: ocInstance}

  it 'Loads enterprises', ->
    expect(Enterprise.index).toHaveBeenCalled()
    expect(scope.enterprises).toEqual('enterprises list')

  it 'Loads enterprise fees', ->
    expect(EnterpriseFee.index).toHaveBeenCalled()
    expect(scope.enterprise_fees).toEqual('enterprise fees list')

  it 'Loads order cycles', ->
    expect(scope.order_cycle).toEqual('my order cycle')

  it 'Submits the order cycle via OrderCycle create', ->
    eventMock = {preventDefault: jasmine.createSpy()}
    scope.submit(eventMock,'/admin/order_cycles')
    expect(eventMock.preventDefault).toHaveBeenCalled()
    expect(OrderCycle.create).toHaveBeenCalledWith('/admin/order_cycles')
