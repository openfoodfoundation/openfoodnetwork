angular.module("admin.orders").controller "ordersCtrl", ($scope, $compile, shops, orderCycles) ->
  $scope.$compile = $compile
  $scope.shops = shops
  $scope.orderCycles = orderCycles
