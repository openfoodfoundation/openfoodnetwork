angular.module("admin.orders").controller "ordersCtrl", ($scope, $timeout, RequestMonitor, Orders, SortOptions, $window, $filter) ->
  $scope.RequestMonitor = RequestMonitor
  $scope.pagination = Orders.pagination
  $scope.orders = Orders.all
  $scope.sortOptions = SortOptions
  $scope.per_page_options = [
    {id: 15, name: t('js.admin.orders.index.per_page', results: 15)},
    {id: 50, name: t('js.admin.orders.index.per_page', results: 50)},
    {id: 100, name: t('js.admin.orders.index.per_page', results: 100)}
  ]
  $scope.selected_orders = []
  $scope.checkboxes = {}
  $scope.selected = false
  $scope.select_all = false
  $scope.poll = 0
  $scope.rowStatus = {}

  $scope.initialise = ->
    $scope.per_page = 15
    $scope.q = {
      completed_at_not_null: true
    }
    $scope.fetchResults()

  $scope.fetchResults = (page=1) ->
    $scope.resetSelected()
    params = {
      'q[completed_at_lt]': $scope['q']['completed_at_lt'],
      'q[completed_at_gt]': $scope['q']['completed_at_gt'],
      'q[state_eq]': $scope['q']['state_eq'],
      'q[number_cont]': $scope['q']['number_cont'],
      'q[email_cont]': $scope['q']['email_cont'],
      'q[bill_address_firstname_start]': $scope['q']['bill_address_firstname_start'],
      'q[bill_address_lastname_start]': $scope['q']['bill_address_lastname_start'],
      # Set default checkbox values to null. See: https://github.com/openfoodfoundation/openfoodnetwork/pull/3076#issuecomment-440010498
      'q[completed_at_not_null]': $scope['q']['completed_at_not_null'] || null,
      'q[distributor_id_in][]': $scope['q']['distributor_id_in'],
      'q[order_cycle_id_in][]': $scope['q']['order_cycle_id_in'],
      'q[s]': $scope.sorting || 'completed_at desc',
      per_page: $scope.per_page,
      page: page
    }
    RequestMonitor.load(Orders.index(params).$promise)

  $scope.resetSelected = ->
    $scope.selected_orders.length = 0
    $scope.selected = false
    $scope.select_all = false
    $scope.checkboxes = {}

  $scope.toggleSelection = (id) ->
    index = $scope.selected_orders.indexOf(id)

    if index == -1
      $scope.selected_orders.push(id)
    else
      $scope.selected_orders.splice(index, 1)

  $scope.toggleAll = ->
    $scope.selected_orders.length = 0
    $scope.orders.forEach (order) ->
      $scope.checkboxes[order.id] = $scope.select_all
      $scope.selected_orders.push order.id if $scope.select_all

  $scope.$watch 'sortOptions', (sort) ->
    return unless sort && sort.predicate != ""

    $scope.sorting = sort.getSortingExpr()
    $scope.fetchResults()
  , true

  $scope.capturePayment = (order) ->
    $scope.rowAction('capture', order)

  $scope.shipOrder = (order) ->
    $scope.rowAction('ship', order)

  $scope.rowAction = (action, order) ->
    $scope.rowStatus[order.id] = "loading"

    Orders[action](order).$promise.then (data) ->
      $scope.rowStatus[order.id] = "success"
      $timeout(->
        $scope.rowStatus[order.id] = null
      , 1500)
    , (error) ->
      $scope.rowStatus[order.id] = "error"

  $scope.changePage = (newPage) ->
    $scope.page = newPage
    $scope.fetchResults(newPage)
