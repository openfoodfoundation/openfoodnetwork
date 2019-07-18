angular.module("admin.subscriptions").controller "OrdersPanelController", ($scope, OrderCycles) ->
  $scope.subscription = $scope.object

  $scope.cancelOrder = (order) ->
    if confirm(t('are_you_sure'))
      $scope.subscription.cancelOrder(order)

  $scope.resumeOrder = (order) ->
    if confirm(t('are_you_sure'))
      $scope.subscription.resumeOrder(order)

  $scope.orderCycleName = (id) ->
    OrderCycles.byID[id].name

  $scope.orderCycleCloses = (id) ->
    oc = OrderCycles.byID[id]
    return t('js.subscriptions.close_date_not_set') unless oc?.orders_close_at?
    closes_at = moment(oc.orders_close_at, "YYYY-MM-DD HH:mm:SS Z")
    text = if closes_at > moment() then t('js.subscriptions.closes') else t('js.subscriptions.closed')
    "#{text} #{closes_at.fromNow()}"

  $scope.stateText = (state) -> t("js.admin.orders.order_state.#{state}")
