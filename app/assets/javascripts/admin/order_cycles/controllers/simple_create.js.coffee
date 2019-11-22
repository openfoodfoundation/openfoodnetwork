angular.module('admin.orderCycles').controller "AdminSimpleCreateOrderCycleCtrl", ($scope, $controller, $window, OrderCycle, Enterprise, EnterpriseFee, ExchangeProduct, StatusMessage, Schedules, RequestMonitor, ocInstance) ->
  $controller('AdminOrderCycleBasicCtrl', {$scope: $scope, ocInstance: ocInstance})

  $scope.order_cycle = OrderCycle.new {coordinator_id: ocInstance.coordinator_id}, =>
    $scope.enterprises = Enterprise.index {coordinator_id: ocInstance.coordinator_id}, (enterprises) =>
      $scope.init(enterprises)
    $scope.enterprise_fees = EnterpriseFee.index(coordinator_id: ocInstance.coordinator_id)

  $scope.init = (enterprises) ->
    enterprise = enterprises[Object.keys(enterprises)[0]]
    OrderCycle.order_cycle.coordinator_id = enterprise.id

    OrderCycle.addDistributor enterprise.id, $scope.setOutgoingExchange
    OrderCycle.addSupplier enterprise.id, $scope.loadExchangeProducts

  $scope.setOutgoingExchange = ->
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

  $scope.loadExchangeProducts = ->
    $scope.incoming_exchange = OrderCycle.order_cycle.incoming_exchanges[0]

    params = { enterprise_id: $scope.incoming_exchange.enterprise_id, incoming: true }
    ExchangeProduct.index params, $scope.storeProductsAndSelectAllVariants

  $scope.storeProductsAndSelectAllVariants = (products) ->
    $scope.enterprises[$scope.incoming_exchange.enterprise_id].supplied_products = products

    # All variants start as checked
    OrderCycle.setExchangeVariants($scope.incoming_exchange,
      Enterprise.suppliedVariants($scope.incoming_exchange.enterprise_id), true)

  $scope.removeDistributionOfVariant = angular.noop

  $scope.submit = ($event, destination) ->
    $event.preventDefault()
    StatusMessage.display 'progress', t('js.saving')
    OrderCycle.mirrorIncomingToOutgoingProducts()
    OrderCycle.create(destination) if OrderCycle.confirmNoDistributors()
