angular.module('admin.orderCycles')
  .controller 'AdminEditOrderCycleCtrl', ($scope, $filter, $location, $window, OrderCycle, Enterprise, EnterpriseFee, StatusMessage) ->
    order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
    $scope.enterprises = Enterprise.index(order_cycle_id: order_cycle_id)
    $scope.supplier_enterprises = Enterprise.producer_enterprises
    $scope.distributor_enterprises = Enterprise.hub_enterprises
    $scope.supplied_products = Enterprise.supplied_products
    $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: order_cycle_id)

    $scope.OrderCycle = OrderCycle
    $scope.order_cycle = OrderCycle.load(order_cycle_id)

    $scope.StatusMessage = StatusMessage

    $scope.$watch 'order_cycle_form.$dirty', (newValue) ->
      StatusMessage.display 'notice', 'You have unsaved changes' if newValue

    $scope.loaded = ->
      Enterprise.loaded && EnterpriseFee.loaded && OrderCycle.loaded

    $scope.suppliedVariants = (enterprise_id) ->
      Enterprise.suppliedVariants(enterprise_id)

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.setExchangeVariants = (exchange, variants, selected) ->
      OrderCycle.setExchangeVariants(exchange, variants, selected)

    $scope.enterpriseTotalVariants = (enterprise) ->
      Enterprise.totalVariants(enterprise)

    $scope.productSuppliedToOrderCycle = (product) ->
      OrderCycle.productSuppliedToOrderCycle(product)

    $scope.variantSuppliedToOrderCycle = (variant) ->
      OrderCycle.variantSuppliedToOrderCycle(variant)

    $scope.incomingExchangeVariantsFor = (enterprise_id) ->
      $filter('filterExchangeVariants')(OrderCycle.incomingExchangesVariants(), $scope.order_cycle.visible_variants_for_outgoing_exchanges[enterprise_id])

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.enterprisesWithFees = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds() when $scope.enterpriseFeesForEnterprise(id).length > 0

    $scope.toggleProducts = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.toggleProducts(exchange)

    $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))

    $scope.addSupplier = ($event) ->
      $event.preventDefault()
      OrderCycle.addSupplier($scope.new_supplier_id)

    $scope.addDistributor = ($event) ->
      $event.preventDefault()
      OrderCycle.addDistributor($scope.new_distributor_id)

    $scope.removeExchange = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.removeExchange(exchange)
      $scope.order_cycle_form.$dirty = true

    $scope.addCoordinatorFee = ($event) ->
      $event.preventDefault()
      OrderCycle.addCoordinatorFee()

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)

    $scope.addExchangeFee = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.addExchangeFee(exchange)

    $scope.removeExchangeFee = ($event, exchange, index) ->
      $event.preventDefault()
      OrderCycle.removeExchangeFee(exchange, index)

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)

    $scope.submit = (destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', "Saving..."

    $scope.submit = ($event, destination) ->
      $event.preventDefault()
      StatusMessage.display 'progress', "Saving..."
      OrderCycle.update(destination, $scope.order_cycle_form)

    $scope.cancel = (destination) ->
      $window.location = destination
