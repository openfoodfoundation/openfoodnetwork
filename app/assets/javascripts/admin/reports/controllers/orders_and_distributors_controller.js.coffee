angular.module("admin.reports").controller "ordersAndDistributorsController", ($scope, $http, OrdersAndDistributorsReport, Enterprises, OrderCycles, LineItems, Orders, Products, Variants) ->
  $scope.orderCycles = OrderCycles.all
  $scope.gridOptions = OrdersAndDistributorsReport.gridOptions()
  $scope.loading = false
  $scope.loadAttempted = false
  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

  $scope.download = ($event, type, visibility) ->
    $event.stopPropagation()
    $event.preventDefault()
    # exporterAllDataPromise???
    if type == 'csv'
      $scope.gridApi.exporter.csvExport(visibility, visibility)
    else
      $scope.gridApi.exporter.pdfExport(visibility, visibility)

  $scope.load = ->
    $scope.loading = true
    $scope.loadAttempted = false
    $scope.gridOptions.data = []
    params = {}
    params["q[#{param}]"] = value for param, value of $scope.q
    $http.get('/admin/reports/orders_and_distributors.json', params: params)
      .success (data) ->
        LineItems.load data.line_items
        Orders.load data.orders
        Variants.load data.variants
        Products.load data.products
        Enterprises.load data.distributors
        Orders.linkToDistributors()
        LineItems.linkToOrders()
        LineItems.linkToVariants()
        $scope.gridOptions.data = LineItems.all
      .finally ->
        $scope.loading = false
        $scope.loadAttempted = true

