angular.module('admin.order_cycles').controller "AdminSimpleEditOrderCycleCtrl", ($scope, $location, OrderCycle, Enterprise, EnterpriseFee) ->
  $scope.orderCycleId = ->
    $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]

  $scope.enterprises = Enterprise.index(order_cycle_id: $scope.orderCycleId())
  $scope.enterprise_fees = EnterpriseFee.index(order_cycle_id: $scope.orderCycleId())
  $scope.order_cycle = OrderCycle.load $scope.orderCycleId(), (order_cycle) =>
    $scope.init()

  $scope.loaded = ->
    Enterprise.loaded && EnterpriseFee.loaded && OrderCycle.loaded

  $scope.init = ->
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

  $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
    EnterpriseFee.forEnterprise(parseInt(enterprise_id))

  $scope.removeDistributionOfVariant = angular.noop

  $scope.setExchangeVariants = (exchange, variants, selected) ->
    OrderCycle.setExchangeVariants(exchange, variants, selected)

  $scope.suppliedVariants = (enterprise_id) ->
    Enterprise.suppliedVariants(enterprise_id)

  $scope.addCoordinatorFee = ($event) ->
    $event.preventDefault()
    OrderCycle.addCoordinatorFee()

  $scope.removeCoordinatorFee = ($event, index) ->
    $event.preventDefault()
    OrderCycle.removeCoordinatorFee(index)

  $scope.submit = (event) ->
    event.preventDefault()
    OrderCycle.mirrorIncomingToOutgoingProducts()
    OrderCycle.update()
