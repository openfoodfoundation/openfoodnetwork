angular.module('admin.orderCycles')
  .controller 'AdminOrderCycleExchangesCtrl', ($scope, $controller, $filter, $window, $location, $timeout, OrderCycle, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $controller('AdminEditOrderCycleCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

    $scope.supplier_enterprises = Enterprise.producer_enterprises
    $scope.distributor_enterprises = Enterprise.hub_enterprises
    $scope.supplied_products = Enterprise.supplied_products

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.enterprisesWithFees = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds() when $scope.enterpriseFeesForEnterprise(id).length > 0

    $scope.removeExchange = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.removeExchange(exchange)
      $scope.order_cycle_form.$dirty = true

    $scope.addExchangeFee = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.addExchangeFee(exchange)

    $scope.removeExchangeFee = ($event, exchange, index) ->
      $event.preventDefault()
      OrderCycle.removeExchangeFee(exchange, index)
      $scope.order_cycle_form.$dirty = true

    $scope.addSupplier = ($event) ->
      $event.preventDefault()
      OrderCycle.addSupplier($scope.new_supplier_id)

    $scope.addDistributor = ($event) ->
      $event.preventDefault()
      OrderCycle.addDistributor($scope.new_distributor_id)

    $scope.setPickupTimeFieldDirty = (index) ->
      $timeout ->
        pickup_time_field_name = "order_cycle_outgoing_exchange_" + index + "_pickup_time"
        $scope.order_cycle_form[pickup_time_field_name].$setDirty()

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)
