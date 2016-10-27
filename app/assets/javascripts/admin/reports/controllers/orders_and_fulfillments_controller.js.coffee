angular.module("admin.reports").controller "ordersAndFulfillmentsController", ($scope, $http ,OrdersAndFulfillmentsReport, Enterprises, OrderCycles, LineItems, Orders, Products, Variants, shops, producers) ->
  $scope.shops = shops
  $scope.producers = producers
  $scope.orderCycles = OrderCycles.all
  $scope.gridOptions = OrdersAndFulfillmentsReport.gridOptions()
  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

  $scope.downloadAsCSV = ->
    $scope.gridApi.exporter.csvExport('all','visible')

  $scope.load = ->
    params = {}
    params["q[#{param}]"] = value for param, value of $scope.q
    $http.get('/admin/reports/orders_and_fulfillment.json', params: params).success (data) ->
      LineItems.load data.line_items
      Orders.load data.orders
      Products.load data.products
      Variants.load data.variants
      LineItems.linkToOrders()
      $scope.gridOptions.data = LineItems.all
