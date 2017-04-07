angular.module("admin.reports").controller "bulkCoopController", ($scope, $http, BulkCoopReport, Enterprises, OrderCycles, LineItems, Orders, Products, Variants, distributors) ->
  $scope.distributors = distributors
  $scope.orderCycles = OrderCycles.all
  $scope.columnOptions = BulkCoopReport.columnOptions()
  $scope.gridOptions = BulkCoopReport.gridOptions()
  $scope.loading = false
  $scope.loadAttempted = false
  $scope.q = {report_type: 'supplier_report'}

  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

  $scope.downloadAsCSV = ->
    $scope.gridApi.exporter.csvExport('all','visible')

  $scope.reload = ->
    $scope.loading = false
    $scope.loadAttempted = false
    $scope.gridOptions.columnDefs = $scope.$eval('columnOptions.'+this.q.report_type)
    $scope.gridOptions.data = new Array()
    $scope.gridApi.grid.refresh()
  $scope.load = ->
    $scope.loading = true
    $scope.loadAttempted = false
    $scope.gridOptions.data = []
    params = {}
    params["q[#{param}]"] = value for param, value of $scope.q
    $http.get('/admin/reports/bulk_coop.json', params: params)
      .success (data) ->
        LineItems.load data.line_items
        Orders.load data.orders
        Variants.load data.variants
        Products.load data.products
        Enterprises.load data.distributors
        LineItems.linkToOrders()
        LineItems.linkToVariants()
        LineItems.linkToProducts()
        $scope.gridOptions.data = LineItems.all
      .finally ->
        $scope.loading = false
        $scope.loadAttempted = true

