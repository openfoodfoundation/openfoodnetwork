angular.module('admin.orderCycles')
  .controller 'AdminCreateOrderCycleCtrl', ($scope, $controller, $filter, $window, OrderCycle, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $controller('AdminOrderCycleBasicCtrl', {$scope: $scope, ocInstance: ocInstance})

    $scope.order_cycle = OrderCycle.new({ coordinator_id: ocInstance.coordinator_id})
    $scope.enterprises = Enterprise.index(coordinator_id: ocInstance.coordinator_id)
    $scope.enterprise_fees = EnterpriseFee.index(coordinator_id: ocInstance.coordinator_id)

    $scope.submit = ($event, destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', t('js.saving')
      OrderCycle.create(destination)
