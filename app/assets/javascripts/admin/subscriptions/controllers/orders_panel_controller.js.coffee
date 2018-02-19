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
    closes_at = moment(OrderCycles.byID[id].orders_close_at)
    text = if closes_at > moment() then t('js.closes') else t('js.closed')
    "#{text} #{closes_at.fromNow()}"

  $scope.stateText = (state) -> t("spree.order_state.#{state}")
