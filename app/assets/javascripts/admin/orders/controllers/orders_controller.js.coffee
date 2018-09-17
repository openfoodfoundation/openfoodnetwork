angular.module("admin.orders").controller "ordersCtrl", ($scope, $injector, RequestMonitor, $compile, $attrs, Orders, SortOptions) ->
  $scope.$compile = $compile
  $scope.shops = shops
  $scope.orderCycles = orderCycles

  $scope.distributor_id = parseInt($attrs.ofnDistributorId)
  $scope.order_cycle_id = parseInt($attrs.ofnOrderCycleId)

  $scope.RequestMonitor = RequestMonitor
  $scope.pagination = Orders.pagination
  $scope.orders = Orders.all
  $scope.sortOptions = SortOptions

  $scope.initialise = ->
    $scope.q = {
      completed_at_not_null: true
    }
    $scope.fetchResults()

  $scope.fetchResults = (page=1) ->
    Orders.index({
      'q[created_at_lt]': $scope['q']['created_at_lt'],
      'q[created_at_gt]': $scope['q']['created_at_gt'],
      'q[state_eq]': $scope['q']['state_eq'],
      'q[number_cont]': $scope['q']['number_cont'],
      'q[email_cont]': $scope['q']['email_cont'],
      'q[bill_address_firstname_start]': $scope['q']['bill_address_firstname_start'],
      'q[bill_address_lastname_start]': $scope['q']['bill_address_lastname_start'],
      'q[completed_at_not_null]': $scope['q']['completed_at_not_null'],
      'q[inventory_units_shipment_id_null]': $scope['q']['inventory_units_shipment_id_null'],
      'q[distributor_id_in]': $scope['q']['distributor_id_in'],
      'q[order_cycle_id_in]': $scope['q']['order_cycle_id_in'],
      'q[order_cycle_id_in]': $scope['q']['order_cycle_id_in'],
      'q[s]': $scope.sorting || 'id desc',
      per_page: $scope.per_page || 15,
      page: page
    })

  $scope.$watch 'sortOptions', (sort) ->
    if sort.predicate != ""
      $scope.sorting = sort.predicate + ' desc' if sort.reverse
      $scope.sorting = sort.predicate + ' asc' if !sort.reverse
      $scope.fetchResults()
  , true

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
    $scope.fetchResults(newPage)

  for oc in $scope.orderCycles
    oc.name_and_status = "#{oc.name} (#{oc.status})"

  for shop in $scope.shops
    shop.disabled = !$scope.distributorHasOrderCycles(shop)
