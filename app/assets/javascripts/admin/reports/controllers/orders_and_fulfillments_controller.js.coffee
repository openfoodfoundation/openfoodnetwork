angular.module("admin.reports").controller "ordersAndFulfillmentsController", ($scope, $http, $location, OrdersAndFulfillmentsReport, Enterprises, OrderCycles, LineItems, Orders, Products, Variants, shops, producers, reportType) ->
  $scope.loading = false
  $scope.loadAttempted = false
  $scope.shops = shops
  $scope.producers = producers
  $scope.orderCycles = OrderCycles.all
  $scope.columnOptions = OrdersAndFulfillmentsReport.columnOptions()

  if $location.search().report_type
    reportType = $location.search().report_type
  $scope.gridOptions = OrdersAndFulfillmentsReport.gridOptions(reportType)
  $scope.q = {report_type: reportType}

  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

  $scope.download = ($event, type, visibility) ->
    $event.stopPropagation()
    $event.preventDefault()
    # exporterAllDataPromise???
    if type == 'csv'
      $scope.gridApi.exporter.csvExport(visibility, visibility)
    else
      $scope.gridApi.exporter.pdfExport(visibility, visibility)

  $scope.reload = ->
    $scope.loading = false
    $scope.loadAttempted = false
    $scope.gridOptions.columnDefs = $scope.$eval('columnOptions.' + this.q.report_type)
    $location.search('report_type', this.q.report_type)
    $scope.gridOptions.data = new Array()
    $scope.gridApi.grid.refresh()

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
