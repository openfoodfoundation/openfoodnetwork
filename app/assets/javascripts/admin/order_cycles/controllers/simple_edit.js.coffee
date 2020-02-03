angular.module('admin.orderCycles').controller "AdminSimpleEditOrderCycleCtrl", ($scope, $controller, $location, $window, OrderCycle, Enterprise, EnterpriseFee, ExchangeProduct, Schedules, RequestMonitor, StatusMessage, ocInstance) ->
  $controller('AdminOrderCycleBasicCtrl', {$scope: $scope, ocInstance: ocInstance})

  $scope.orderCycleId = ->
    $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]

  $scope.enterprises = Enterprise.index(order_cycle_id: $scope.orderCycleId())
  $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: $scope.orderCycleId())
  $scope.order_cycle = OrderCycle.load $scope.orderCycleId(), (order_cycle) =>
    $scope.init()

  $scope.init = ->
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]
    $scope.incoming_exchange = OrderCycle.order_cycle.incoming_exchanges[0]
    $scope.loadExchangeProducts($scope.incoming_exchange)

  $scope.loadExchangeProducts = (exchange, page = 1) ->
    enterprise = $scope.enterprises[exchange.enterprise_id]
    enterprise.supplied_products ?= []

    return if enterprise.last_page_loaded? && enterprise.last_page_loaded >= page
    enterprise.last_page_loaded = page

    params = {
      exchange_id: exchange.id,
      page: page,
    }
    ExchangeProduct.index params, (products, num_of_pages, num_of_products) ->
      enterprise.num_of_pages = num_of_pages
      enterprise.num_of_products = num_of_products
      enterprise.supplied_products.push products...

  $scope.loadMoreExchangeProducts = (exchange) ->
    $scope.loadExchangeProducts(exchange, $scope.enterprises[exchange.enterprise_id].last_page_loaded + 1)

  $scope.loadAllExchangeProducts = (exchange) ->
    enterprise = $scope.enterprises[exchange.enterprise_id]

    if enterprise.last_page_loaded < enterprise.num_of_pages
      for page_to_load in [(enterprise.last_page_loaded + 1)..enterprise.num_of_pages]
        RequestMonitor.load $scope.loadExchangeProducts(exchange, page_to_load).$promise

    RequestMonitor.loadQueue

  $scope.removeDistributionOfVariant = angular.noop

  $scope.submit = ($event, destination) ->
    $event.preventDefault()
    StatusMessage.display 'progress', t('js.saving')
    OrderCycle.mirrorIncomingToOutgoingProducts()
    OrderCycle.update(destination, $scope.order_cycle_form) if OrderCycle.confirmNoDistributors()
