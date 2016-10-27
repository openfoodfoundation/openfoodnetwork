angular.module("admin.reports").controller "ordersAndFulfillmentsController", ($scope, $http, OrdersAndFulfillmentsReport, Enterprises, OrderCycles, LineItems, Orders, Products, Variants) ->
  $scope.enterprises = Enterprises.all
  $scope.orderCycles = OrderCycles.all
  $scope.gridOptions = OrdersAndFulfillmentsReport.gridOptions()

  $http.get('/admin/reports/orders_and_fulfillment.json').success (data) ->
    LineItems.load data.line_items
    Orders.load data.orders
    Products.load data.products
    Variants.load data.variants
    LineItems.linkToOrders()
    $scope.gridOptions.data = LineItems.all
