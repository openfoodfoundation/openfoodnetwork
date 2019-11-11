angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $controller, $location, Enterprise, ocInstance) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

  $scope.view = 'incoming'

  $scope.exchangeTotalVariants = (exchange) ->
    return unless this.enterprises? && this.enterprises[exchange.enterprise_id]?

    enterprise = this.enterprises[exchange.enterprise_id]
    return enterprise.numVariants if enterprise.numVariants?

    $scope.loadExchangeProducts(this, exchange)
    return unless enterprise.supplied_products?

    enterprise.numVariants = $scope.countVariants(enterprise.supplied_products)

  $scope.countVariants = (products) ->
    return 0 unless products

    numVariants = 0
    for product in products
      numVariants += product.variants.length
    numVariants
