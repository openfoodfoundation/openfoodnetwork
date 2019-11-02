angular.module('admin.orderCycles').controller "AdminSimpleCreateOrderCycleCtrl", ($scope, $controller, $window, OrderCycle, Enterprise, EnterpriseFee, StatusMessage, Schedules, RequestMonitor, ocInstance) ->
  $controller('AdminOrderCycleBasicCtrl', {$scope: $scope})

  $scope.StatusMessage = StatusMessage
  $scope.OrderCycle = OrderCycle
  $scope.schedules = Schedules.index({enterprise_id: ocInstance.coordinator_id})
  $scope.order_cycle = OrderCycle.new {coordinator_id: ocInstance.coordinator_id}, =>
    # TODO: make this a get method, which only fetches one enterprise
    $scope.enterprises = Enterprise.index {coordinator_id: ocInstance.coordinator_id}, (enterprises) =>
      $scope.init(enterprises)
    $scope.enterprise_fees = EnterpriseFee.index(coordinator_id: ocInstance.coordinator_id)

  $scope.init = (enterprises) ->
    enterprise = enterprises[Object.keys(enterprises)[0]]
    OrderCycle.addSupplier enterprise.id
    OrderCycle.addDistributor enterprise.id
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

    # All variants start as checked
    OrderCycle.setExchangeVariants(OrderCycle.order_cycle.incoming_exchanges[0],
      Enterprise.suppliedVariants(enterprise.id), true)

    OrderCycle.order_cycle.coordinator_id = enterprise.id

  $scope.removeDistributionOfVariant = angular.noop

  $scope.submit = ($event, destination) ->
    $event.preventDefault()
    StatusMessage.display 'progress', t('js.saving')
    OrderCycle.mirrorIncomingToOutgoingProducts()
    OrderCycle.create(destination)
