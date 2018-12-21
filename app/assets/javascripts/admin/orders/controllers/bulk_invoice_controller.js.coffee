angular.module("admin.orders").controller "bulkInvoiceCtrl", ($scope, $http, $timeout) ->
  $scope.createBulkInvoice = ->
    $scope.invoice_id = null
    $scope.poll = 1
    $scope.loading = true
    $scope.message = null
    $scope.error = null

    $http.post('/admin/orders/invoices', {order_ids: $scope.selected_orders}).success (data) ->
      $scope.invoice_id = data
      $scope.pollBulkInvoice()

  $scope.pollBulkInvoice = ->
    $timeout($scope.nextPoll, 5000)

  $scope.nextPoll = ->
    $http.get('/admin/orders/invoices/'+$scope.invoice_id+'/poll').success (data) ->
      $scope.loading = false
      $scope.message = t('js.admin.orders.index.bulk_invoice_created')

    .error (data) ->
      $scope.poll++

      if $scope.poll > 30
        $scope.loading = false
        $scope.error = t('js.admin.orders.index.bulk_invoice_failed')
        return

      $scope.pollBulkInvoice()

