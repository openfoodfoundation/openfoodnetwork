describe "ordersAndDistributorsCtrl", ->
  ctrl = $httpBackend = null
  scope = controller = {}

  Report = {
    gridOptions: ->
      onRegisterApi: ->
  }

  beforeEach ->
    scope = {}

    module('admin.reports')
    inject ($controller, _$httpBackend_) ->
      $httpBackend = _$httpBackend_
      ctrl = $controller 'ordersAndDistributorsCtrl', {$scope: scope, OrdersAndDistributorsReport: Report}

  it "init ui-grid loading flags should be false", ->
    expect(scope.loading).toBe false
    expect(scope.loadAttempted).toBe false

  it "can load reports", ->
    $httpBackend.expectGET("/admin/reports/orders_and_distributors.json").respond 200

    scope.load()

    expect(scope.loading).toBe true
    expect(scope.loadAttempted).toBe false
    expect(scope.gridOptions.data).toEqual []

