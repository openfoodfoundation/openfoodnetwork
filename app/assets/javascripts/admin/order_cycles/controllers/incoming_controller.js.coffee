angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $controller, $location, Enterprise, OrderCycle, ocInstance) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

  $scope.view = 'incoming'

  $scope.exchangeTotalVariants = (exchange) ->
    return unless $scope.enterprises? && $scope.enterprises[exchange.enterprise_id]?

    enterprise = $scope.enterprises[exchange.enterprise_id]
    return enterprise.numVariants if enterprise.numVariants?

    $scope.loadExchangeProducts(exchange)
    return unless enterprise.supplied_products?

    enterprise.numVariants = $scope.countVariants(enterprise.supplied_products)

  $scope.countVariants = (products) ->
    return 0 unless products

    numVariants = 0
    for product in products
      numVariants += product.variants.length
    numVariants

  $scope.addSupplier = ($event) ->
    $event.preventDefault()
    OrderCycle.addSupplier $scope.new_supplier_id, $scope.exchangeListChanged
