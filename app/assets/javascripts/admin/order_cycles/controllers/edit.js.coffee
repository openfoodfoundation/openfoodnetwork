angular.module('admin.orderCycles')
  .controller 'AdminEditOrderCycleCtrl', ($scope, $controller, $filter, $location, $window, OrderCycle, Enterprise, EnterpriseFee, StatusMessage, Schedules, RequestMonitor, ocInstance) ->
    $controller('AdminOrderCycleCtrl', {$scope: $scope})

    order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
    $scope.order_cycle = OrderCycle.load(order_cycle_id)

    $scope.enterprises = Enterprise.index(order_cycle_id: order_cycle_id)
    $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: order_cycle_id)

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)
      $scope.order_cycle_form.$dirty = true

    $scope.removeExchangeFee = ($event, exchange, index) ->
      $event.preventDefault()
      OrderCycle.removeExchangeFee(exchange, index)
      $scope.order_cycle_form.$dirty = true

    $scope.submit = (destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', t('js.saving')

    $scope.submit = ($event, destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', t('js.saving')
      OrderCycle.update(destination, $scope.order_cycle_form)
