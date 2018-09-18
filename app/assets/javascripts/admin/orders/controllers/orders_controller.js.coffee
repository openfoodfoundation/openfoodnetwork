angular.module("admin.orders").controller "ordersCtrl", ($scope, RequestMonitor, Orders, SortOptions) ->
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
    if sort && sort.predicate != ""
      $scope.sorting = sort.predicate + ' desc' if sort.reverse
      $scope.sorting = sort.predicate + ' asc' if !sort.reverse
      $scope.fetchResults()
  , true

  $scope.changePage = (newPage) ->
    $scope.page = newPage
    $scope.fetchResults(newPage)
