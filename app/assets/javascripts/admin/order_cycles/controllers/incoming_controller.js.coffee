angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $controller, $location, Enterprise, OrderCycle, ExchangeProduct, ocInstance) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

  $scope.view = 'incoming'

  $scope.exchangeTotalVariants = (exchange) ->
    return unless $scope.enterprises? && $scope.enterprises[exchange.enterprise_id]?

    enterprise = $scope.enterprises[exchange.enterprise_id]
    return enterprise.numVariants if enterprise.numVariants?

    enterprise.numVariants = 0
    params = { exchange_id: exchange.id, enterprise_id: exchange.enterprise_id, order_cycle_id: $scope.order_cycle.id, incoming: true}
    ExchangeProduct.countVariants params, (variants_count) ->
      enterprise.numVariants = variants_count
    return enterprise.numVariants

  $scope.addSupplier = ($event) ->
    $event.preventDefault()
    OrderCycle.addSupplier $scope.new_supplier_id
