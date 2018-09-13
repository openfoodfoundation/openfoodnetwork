angular.module("admin.orders").controller "ordersCtrl", ($scope, RequestMonitor, $compile, $attrs, Orders) ->
  $scope.$compile = $compile
  $scope.shops = shops
  $scope.orderCycles = orderCycles

  $scope.distributor_id = parseInt($attrs.ofnDistributorId)
  $scope.order_cycle_id = parseInt($attrs.ofnOrderCycleId)

  $scope.RequestMonitor = RequestMonitor
  $scope.orders = Orders.all
  $scope.pagination = Orders.pagination

  $scope.initialise = ->
    $scope.fetchResults()

  $scope.fetchResults = ->
    Orders.index({
      per_page: $scope.per_page || 15,
      page: $scope.page || 1
    })

  $scope.validOrderCycle = (oc) ->
    $scope.orderCycleHasDistributor oc, parseInt($scope.distributor_id)

  $scope.distributorHasOrderCycles = (distributor) ->
    (oc for oc in orderCycles when @orderCycleHasDistributor(oc, distributor.id)).length > 0

  $scope.orderCycleHasDistributor = (oc, distributor_id) ->
    distributor_ids = (d.id for d in oc.distributors)
    distributor_ids.indexOf(distributor_id) != -1

  $scope.distributionChosen = ->
    $scope.distributor_id && $scope.order_cycle_id

  $scope.changePage = (newPage) ->
    $scope.page = newPage
    Orders.resetData()
    $scope.fetchResults()

  for oc in $scope.orderCycles
    oc.name_and_status = "#{oc.name} (#{oc.status})"

  for shop in $scope.shops
    shop.disabled = !$scope.distributorHasOrderCycles(shop)
