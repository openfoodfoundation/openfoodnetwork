angular.module('admin.orderCycles')
  .controller 'AdminOrderCycleExchangesCtrl', ($scope, $controller, $filter, $window, $location, OrderCycle, ExchangeProduct, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $controller('AdminEditOrderCycleCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

    $scope.supplier_enterprises = Enterprise.producer_enterprises
    $scope.distributor_enterprises = Enterprise.hub_enterprises

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

    $scope.setPickupTimeFieldDirty = (index) ->
      $timeout ->
        pickup_time_field_name = "order_cycle_outgoing_exchange_" + index + "_pickup_time"
        $scope.order_cycle_form[pickup_time_field_name].$setDirty()

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)

    $scope.loadExchangeProducts = (exchange) ->
      return if $scope.enterprises[exchange.enterprise_id].supplied_products_fetched?
      $scope.enterprises[exchange.enterprise_id].supplied_products_fetched = true

      incoming = true if $scope.view == 'incoming'
      params = { exchange_id: exchange.id, enterprise_id: exchange.enterprise_id, order_cycle_id: $scope.order_cycle.id, incoming: incoming}
      ExchangeProduct.index params, (products) ->
        $scope.enterprises[exchange.enterprise_id].supplied_products = products

    # Register listeners to capture first toggle open of the products panel of the exchange
    $scope.exchangeListChanged = ->
      panelRows = angular.element(".panel-row")
      for panelRow in panelRows
        panelCtrl = angular.element(panelRow).controller('panelCtrl')
        panelCtrl.registerSelectionListener($scope.initializeExchangeProductsPanel)

    # initialize exchange products panel if not yet done
    $scope.exchangeProdutsPanelInitialized = []
    $scope.initializeExchangeProductsPanel = (selection, $element) ->
      scope = $element.scope()
      return if $scope.exchangeProdutsPanelInitialized[scope.exchange.enterprise_id]
      $scope.loadExchangeProducts(scope.exchange)
      $scope.exchangeProdutsPanelInitialized[scope.exchange.enterprise_id] = true
