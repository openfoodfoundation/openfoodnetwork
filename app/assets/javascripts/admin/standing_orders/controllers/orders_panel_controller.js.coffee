angular.module("admin.standingOrders").controller "OrdersPanelController", ($scope, OrderCycles) ->
  $scope.standingOrder = $scope.object

  $scope.cancelOrder = (order) ->
    if confirm(t('are_you_sure'))
      $scope.standingOrder.cancelOrder(order)

  $scope.resumeOrder = (order) ->
    if confirm(t('are_you_sure'))
      $scope.standingOrder.resumeOrder(order)

  $scope.orderCycleName = (id) ->
    OrderCycles.byID[id].name

  $scope.orderCycleCloses = (id) ->
    closes_at = moment(OrderCycles.byID[id].orders_close_at)
    text = if closes_at > moment() then t('closes') else t('closed')
    "#{text} #{closes_at.fromNow()}"
