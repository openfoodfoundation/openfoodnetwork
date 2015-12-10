angular.module("admin.orders").controller "ordersCtrl", ($scope, $compile, $attrs, shops, orderCycles) ->
  $scope.$compile = $compile
  $scope.shops = shops
  $scope.orderCycles = orderCycles
  for oc in $scope.orderCycles
    oc.name_and_status = "#{oc.name} (#{oc.status})"

  $scope.distributor_id = $attrs.ofnDistributorId
  $scope.order_cycle_id = $attrs.ofnOrderCycleId

  $scope.validOrderCycle = (oc, index, array) ->
    $scope.orderCycleHasDistributor oc, parseInt($scope.distributor_id)

  $scope.distributorHasOrderCycles = (distributor) ->
    (oc for oc in orderCycles when @orderCycleHasDistributor(oc, distributor.id)).length > 0

  $scope.orderCycleHasDistributor = (oc, distributor_id) ->
    distributor_ids = (d.id for d in oc.distributors)
    distributor_ids.indexOf(distributor_id) != -1

  $scope.distributionChosen = ->
    $scope.distributor_id && $scope.order_cycle_id
