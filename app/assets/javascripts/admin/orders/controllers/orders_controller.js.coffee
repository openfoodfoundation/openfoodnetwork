angular.module("admin.orders").controller "ordersCtrl", ($scope, RequestMonitor, Orders, SortOptions) ->
  $scope.RequestMonitor = RequestMonitor
  $scope.pagination = Orders.pagination
  $scope.orders = Orders.all
  $scope.sortOptions = SortOptions
  $scope.per_page_options = [
    {id: 15, name: t('js.admin.orders.index.per_page', results: 15)},
    {id: 50, name: t('js.admin.orders.index.per_page', results: 50)},
    {id: 100, name: t('js.admin.orders.index.per_page', results: 100)}
  ]

  $scope.initialise = ->
    $scope.per_page = 15
    $scope.q = {
      completed_at_not_null: true
    }
    $scope.fetchResults()

  $scope.fetchResults = (page=1) ->
    Orders.index({
      'q[completed_at_lt]': $scope['q']['completed_at_lt'],
      'q[completed_at_gt]': $scope['q']['completed_at_gt'],
      'q[state_eq]': $scope['q']['state_eq'],
      'q[number_cont]': $scope['q']['number_cont'],
      'q[email_cont]': $scope['q']['email_cont'],
      'q[bill_address_firstname_start]': $scope['q']['bill_address_firstname_start'],
      'q[bill_address_lastname_start]': $scope['q']['bill_address_lastname_start'],
      # Set default checkbox values to null. See: https://github.com/openfoodfoundation/openfoodnetwork/pull/3076#issuecomment-440010498
      'q[completed_at_not_null]': $scope['q']['completed_at_not_null'] || null,
      'q[inventory_units_shipment_id_null]': $scope['q']['inventory_units_shipment_id_null'] || null,
      'q[distributor_id_in]': $scope['q']['distributor_id_in'],
      'q[order_cycle_id_in]': $scope['q']['order_cycle_id_in'],
      'q[order_cycle_id_in]': $scope['q']['order_cycle_id_in'],
      'q[s]': $scope.sorting || 'completed_at desc',
      per_page: $scope.per_page,
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
