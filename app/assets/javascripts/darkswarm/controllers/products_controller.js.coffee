angular.module("Shop").controller "ProductsCtrl", ($scope, $rootScope, Product, OrderCycle) ->
  $scope.data = Product.data
  $scope.order_cycle = OrderCycle.order_cycle
  Product.update()
