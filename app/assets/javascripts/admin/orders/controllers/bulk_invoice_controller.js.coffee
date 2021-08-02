angular.module("admin.orders").controller "bulkInvoiceCtrl", ($scope, $http, $timeout) ->
  $scope.createBulkInvoice = ->
    $scope.invoice_id = null
    $scope.poll = 1
    $scope.loading = true
    $scope.message = null
    $scope.error = null
    $scope.poll_wait = 5 # 5 Seconds between each check
    $scope.poll_retries = 80 # Maximum checks before stopping

    $http.post('/admin/orders/invoices', {order_ids: $scope.selected_orders}).then (response) ->
      $scope.invoice_id = response.data
      $scope.pollBulkInvoice()

  $scope.pollBulkInvoice = ->
    $timeout($scope.nextPoll, $scope.poll_wait * 1000)

  $scope.nextPoll = ->
    $http.get('/admin/orders/invoices/'+$scope.invoice_id+'/poll').then (response) ->
      $scope.loading = false
      $scope.message = t('js.admin.orders.index.bulk_invoice_created')

    .catch (response) ->
      $scope.poll++

      if $scope.poll > $scope.poll_retries
        $scope.loading = false
        $scope.error = t('js.admin.orders.index.bulk_invoice_failed')
        return

      $scope.pollBulkInvoice()

