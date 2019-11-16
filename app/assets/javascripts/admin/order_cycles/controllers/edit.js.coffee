angular.module('admin.orderCycles')
  .controller 'AdminEditOrderCycleCtrl', ($scope, $controller, $filter, $location, $window, OrderCycle, Enterprise, EnterpriseFee, StatusMessage, Schedules, RequestMonitor, ocInstance) ->
    $controller('AdminOrderCycleBasicCtrl', {$scope: $scope, ocInstance: ocInstance})

    order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
    $scope.order_cycle = OrderCycle.load order_cycle_id, ->
      $scope.exchangeListChanged() if $scope.exchangeListChanged?

    $scope.enterprises = Enterprise.index(order_cycle_id: order_cycle_id)
    $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: order_cycle_id)

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)
      $scope.order_cycle_form.$dirty = true

    $scope.submit = (destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', t('js.saving')

    $scope.submit = ($event, destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', t('js.saving')
      OrderCycle.update(destination, $scope.order_cycle_form)
