angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $rootScope, $controller, $location, Enterprise, EnterpriseFee, OrderCycle, ExchangeProduct, ocInstance) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

  $scope.view = 'incoming'
  # NB: weirdly at this next line $scope.order_cycle.id comes out undefined so we use $scope.order_cycle_id instead
  $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: $scope.order_cycle_id, per_item: true)
  $scope.exchangeTotalVariants = (exchange) ->
    return unless $scope.enterprises? && $scope.enterprises[exchange.enterprise_id]?

    enterprise = $scope.enterprises[exchange.enterprise_id]
    return enterprise.numVariants if enterprise.numVariants?

    enterprise.numVariants = 0
    params = { exchange_id: exchange.id, enterprise_id: exchange.enterprise_id, order_cycle_id: $scope.order_cycle.id, incoming: true}
    ExchangeProduct.countVariants params, (variants_count) ->
      enterprise.numVariants = variants_count
      $scope.setSelectAllVariantsCheckboxValue(exchange, enterprise.numVariants)

    return enterprise.numVariants

  $scope.addSupplier = ($event) ->
    $event.preventDefault()
    OrderCycle.addSupplier $scope.new_supplier_id

  # To select all variants we first need to load them all from the server
  #
  # This is only needed in Incoming exchanges as here we use supplied_products,
  #   in Outgoing Exchanges the variants are loaded as part of the Exchange payload
  $scope.selectAllVariants = (exchange, selected) ->
    $scope.loadAllExchangeProducts(exchange).then ->
      $scope.setExchangeVariants(exchange, $scope.suppliedVariants(exchange.enterprise_id), selected)
      $rootScope.$evalAsync()
