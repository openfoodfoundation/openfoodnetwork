angular.module("admin.orders").controller "orderCtrl", ($scope, shops, orderCycles, $compile, $attrs, Orders) ->
  $scope.$compile = $compile
  $scope.shops = shops
  $scope.orderCycles = orderCycles

  $scope.distributor_id = parseInt($attrs.ofnDistributorId)
  $scope.order_cycle_id = parseInt($attrs.ofnOrderCycleId)

  $scope.validOrderCycle = (oc) ->
    $scope.orderCycleHasDistributor oc, parseInt($scope.distributor_id)

  $scope.distributorHasOrderCycles = (distributor) ->
    (oc for oc in $scope.orderCycles when @orderCycleHasDistributor(oc, distributor.id)).length > 0

  $scope.orderCycleHasDistributor = (oc, distributor_id) ->
    distributor_ids = (d.id for d in oc.distributors)
    distributor_ids.indexOf(distributor_id) != -1

  $scope.distributionChosen = ->
    $scope.distributor_id && $scope.order_cycle_id

  for oc in $scope.orderCycles
    oc.name_and_status = "#{oc.name} (#{t("admin.order_cycles.status.#{oc.status}")})"

  for shop in $scope.shops
    shop.disabled = !$scope.distributorHasOrderCycles(shop)
