angular.module("admin.orders").controller "bulkCancelCtrl", ($scope, $http, $timeout) ->

  $scope.cancelOrder = (orderIds, sendEmailCancellation, restock_items) ->
    $http(
      method: 'post'
      url: "/admin/orders/bulk_cancel?order_ids=#{orderIds}&send_cancellation_email=#{sendEmailCancellation}&restock_items=#{restock_items}" ).then(->
        window.location.reload()
      )

  $scope.cancelSelectedOrders = ->
    ofnCancelOrderAlert((confirm, sendEmailCancellation, restock_items) ->
      if confirm
        $scope.cancelOrder $scope.selected_orders, sendEmailCancellation, restock_items
    )
