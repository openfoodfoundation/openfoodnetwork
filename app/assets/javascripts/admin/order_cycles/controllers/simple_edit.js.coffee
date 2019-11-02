angular.module('admin.orderCycles').controller "AdminSimpleEditOrderCycleCtrl", ($scope, $controller, $location, $window, OrderCycle, Enterprise, EnterpriseFee, Schedules, RequestMonitor, StatusMessage, ocInstance) ->
  $controller('AdminOrderCycleBasicCtrl', {$scope: $scope})

  $scope.orderCycleId = ->
    $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]

  $scope.StatusMessage = StatusMessage
  $scope.enterprises = Enterprise.index(order_cycle_id: $scope.orderCycleId())
  $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: $scope.orderCycleId())
  $scope.schedules = Schedules.index({enterprise_id: ocInstance.coordinator_id})
  $scope.OrderCycle = OrderCycle
  $scope.order_cycle = OrderCycle.load $scope.orderCycleId(), (order_cycle) =>
    $scope.init()

  $scope.init = ->
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

  $scope.removeDistributionOfVariant = angular.noop

  $scope.submit = ($event, destination) ->
    $event.preventDefault()
    StatusMessage.display 'progress', t('js.saving')
    OrderCycle.mirrorIncomingToOutgoingProducts()
    OrderCycle.update(destination, $scope.order_cycle_form)
