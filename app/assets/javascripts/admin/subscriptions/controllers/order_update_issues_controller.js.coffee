angular.module("admin.subscriptions").controller "OrderUpdateIssuesController", ($scope, OrderCycles) ->
  $scope.proxyOrders = $scope.options.proxyOrders

  $scope.orderCycleName = (id) ->
    OrderCycles.byID[id].name

  $scope.orderCycleCloses = (id) ->
    closes_at = moment(OrderCycles.byID[id].orders_close_at)
    text = if closes_at > moment() then t('js.closes') else t('js.closed')
    "#{text} #{closes_at.fromNow()}"
