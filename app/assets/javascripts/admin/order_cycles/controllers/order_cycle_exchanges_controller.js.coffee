angular.module('admin.orderCycles')
  .controller 'AdminOrderCycleExchangesCtrl', ($scope, $controller, $filter, $window, $location, $timeout, OrderCycle, ExchangeProduct, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $controller('AdminEditOrderCycleCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

    $scope.supplier_enterprises = Enterprise.producer_enterprises
    $scope.distributor_enterprises = Enterprise.hub_enterprises

    $scope.productsLoading = ->
      RequestMonitor.loading

    $scope.setSelectAllVariantsCheckboxValue = (exchange, totalNumberOfVariants) ->
      exchange.select_all_variants = $scope.exchangeSelectedVariants(exchange) >= totalNumberOfVariants

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.enterprisesWithFees = ->
      ids = [OrderCycle.participatingEnterpriseIds()..., [OrderCycle.order_cycle.coordinator_id]...]
      $scope.enterprises[id] for id in Array.from(new Set(ids)) when $scope.enterpriseFeesForEnterprise(id).length > 0

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

    $scope.setPickupTimeFieldDirty = (index, pickup_time) ->
      # if the pickup_time is already set we are in edit mode, so no need to set pickup_time field as dirty
      # to show it is required (it has a red border when set to dirty)
      return if pickup_time

      $timeout ->
        pickup_time_field_name = "order_cycle_outgoing_exchange_" + index + "_pickup_time"
        $scope.order_cycle_form[pickup_time_field_name].$setDirty()

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)

    $scope.loadExchangeProducts = (exchange, page = 1) ->
      enterprise = $scope.enterprises[exchange.enterprise_id]
      enterprise.supplied_products ?= []

      return if enterprise.last_page_loaded? && enterprise.last_page_loaded >= page
      enterprise.last_page_loaded = page
      enterprise.loaded_variants ?= 0

      incoming = true if $scope.view == 'incoming'
      params = { exchange_id: exchange.id, enterprise_id: exchange.enterprise_id, order_cycle_id: $scope.order_cycle.id, incoming: incoming, page: page}
      ExchangeProduct.index params, (products, num_of_pages) ->
        enterprise.num_of_pages = num_of_pages
        enterprise.supplied_products.push products...
        angular.forEach products, (product) ->
          enterprise.loaded_variants += product.variants.length

    $scope.loadMoreExchangeProducts = (exchange) ->
      $scope.loadExchangeProducts(exchange, $scope.enterprises[exchange.enterprise_id].last_page_loaded + 1)

    $scope.loadAllExchangeProducts = (exchange) ->
      enterprise = $scope.enterprises[exchange.enterprise_id]

      if enterprise.last_page_loaded < enterprise.num_of_pages
        for page_to_load in [(enterprise.last_page_loaded + 1)..enterprise.num_of_pages]
          RequestMonitor.load $scope.loadExchangeProducts(exchange, page_to_load).$promise

      RequestMonitor.loadQueue

    # initialize exchange products panel if not yet done
    $scope.exchangeProdutsPanelInitialized = []
    $scope.initializeExchangeProductsPanel = (exchange) ->
      return if $scope.exchangeProdutsPanelInitialized[exchange.enterprise_id]
      RequestMonitor.load $scope.loadExchangeProducts(exchange).$promise
      $scope.exchangeProdutsPanelInitialized[exchange.enterprise_id] = true
