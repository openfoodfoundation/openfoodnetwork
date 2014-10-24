angular.module('admin.order_cycles').controller "AdminSimpleCreateOrderCycleCtrl", ($scope, OrderCycle, Enterprise, EnterpriseFee) ->
  $scope.enterprises = Enterprise.index (enterprises) =>
    $scope.init(enterprises)
  $scope.enterprise_fees = EnterpriseFee.index()
  $scope.order_cycle = OrderCycle.order_cycle

  $scope.init = (enterprises) ->
    enterprise = enterprises[Object.keys(enterprises)[0]]
    OrderCycle.addSupplier enterprise.id
    OrderCycle.addDistributor enterprise.id
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

    # All variants start as checked
    OrderCycle.setExchangeVariants(OrderCycle.order_cycle.incoming_exchanges[0],
      Enterprise.suppliedVariants(enterprise.id), true)

    OrderCycle.order_cycle.coordinator_id = enterprise.id

  $scope.loaded = ->
    Enterprise.loaded && EnterpriseFee.loaded

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

  $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
    EnterpriseFee.forEnterprise(parseInt(enterprise_id))

  $scope.submit = ->
    OrderCycle.mirrorIncomingToOutgoingProducts()
    OrderCycle.create()
