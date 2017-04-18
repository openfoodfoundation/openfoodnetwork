angular.module("admin.reports").controller "ordersAndFulfillmentsCtrl", ($scope, $controller, $http, $location, OrdersAndFulfillmentsReport, Enterprises, OrderCycles, LineItems, Orders, Products, Variants, shops, producers, reportType) ->
  angular.extend this, $controller('ReportsCtrl', {$scope: $scope, $location: $location})

  $scope.shops = shops
  $scope.producers = producers
  $scope.orderCycles = OrderCycles.all
  $scope.columnOptions = OrdersAndFulfillmentsReport.columnOptions()

  if $location.search().report_type
    reportType = $location.search().report_type
  $scope.q = {report_type: reportType}

  $scope.gridOptions = OrdersAndFulfillmentsReport.gridOptions(reportType)
  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

  $scope.load = ->
    $scope.loading = true
    $scope.loadAttempted = false
    $scope.gridOptions.data = []
    params = {}
    params["q[#{param}]"] = value for param, value of $scope.q
    $http.get('/admin/reports/orders_and_fulfillment.json', params: params)
      .success (data) ->
        LineItems.load data.line_items
        Orders.load data.orders
        Products.load data.products
        Variants.load data.variants
        LineItems.linkToOrders()
        LineItems.linkToProducts()
        $scope.gridOptions.data = LineItems.all
      .finally ->
        $scope.loading = false
        $scope.loadAttempted = true
