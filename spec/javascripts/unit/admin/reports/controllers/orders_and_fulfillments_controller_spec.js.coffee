describe "ordersAndFulfillmentsCtrl", ->
  ctrl = $httpBackend = null
  scope = controller = {}

  reportType = 'supplier_totals'
  Report = {
    gridOptions: ->
      onRegisterApi: ->
    columnOptions: ->
  }

  beforeEach ->
    scope = {}

    module('admin.reports')
    inject ($controller, _$httpBackend_) ->
      $httpBackend = _$httpBackend_
      ctrl = $controller 'ordersAndFulfillmentsCtrl', {$scope: scope, OrdersAndFulfillmentsReport: Report, shops: [], producers: [], orderCycles: [], reportType: reportType }

  it "init ui-grid loading flags should be false", ->
    expect(scope.loading).toBe false
    expect(scope.loadAttempted).toBe false

  it "can load reports", ->
    $httpBackend.expectGET("/admin/reports/bulk_coop.json").respond 200

    scope.load()

    expect(scope.loading).toBe true
    expect(scope.loadAttempted).toBe false
    expect(scope.gridOptions.data).toEqual []


