angular.module("admin.reports").controller "bulkCoopCtrl", ($scope, $controller, $location, $http, BulkCoopReport, Enterprises, LineItems, Orders, Products, Variants, distributors, reportType) ->
  angular.extend this, $controller('ReportsCtrl', {$scope: $scope, $location: $location})

  if $location.search().report_type
    reportType = $location.search().report_type
  $scope.q = {report_type: reportType}
  $scope.reportType = reportType

  $scope.distributors = distributors
  $scope.columnOptions = BulkCoopReport.columnOptions()
  $scope.gridOptions = BulkCoopReport.gridOptions(reportType)
  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

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

