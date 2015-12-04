angular.module("admin.orders").controller "ordersCtrl", ($scope, $compile, $attrs, shops, orderCycles) ->
  $scope.$compile = $compile
  $scope.shops = shops
  $scope.orderCycles = orderCycles

  $scope.distributor_id = $attrs.ofnDistributorId
  $scope.order_cycle_id = $attrs.ofnOrderCycleId

  $scope.validOrderCycle = (oc, index, array) ->
    distributor_ids = (d.id for d in oc.distributors)
    distributor_ids.indexOf(parseInt($scope.distributor_id)) != -1
