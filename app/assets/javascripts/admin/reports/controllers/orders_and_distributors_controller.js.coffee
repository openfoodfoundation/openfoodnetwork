angular.module("admin.reports").controller "ordersAndDistributorsCtrl", ($scope, $controller, $http, OrdersAndDistributorsReport, Enterprises, LineItems, Orders, Products, Variants) ->
  angular.extend this, $controller('ReportsCtrl', {$scope: $scope})

  $scope.gridOptions = OrdersAndDistributorsReport.gridOptions()
  $scope.gridOptions.onRegisterApi = (gridApi) -> $scope.gridApi = gridApi

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

