angular.module("admin.subscriptions").controller "OrderUpdateIssuesController", ($scope, OrderCycles) ->
  $scope.proxyOrders = $scope.options.proxyOrders

  $scope.orderCycleName = (id) ->
    OrderCycles.byID[id].name

  $scope.orderCycleCloses = (id) ->
    closes_at = moment(OrderCycles.byID[id].orders_close_at, "YYYY-MM-DD HH:mm:SS Z")
    key = if closes_at > moment() then "closes" else "closed"
    text = t("js.subscriptions." + key)
    "#{text} #{closes_at.fromNow()}"
