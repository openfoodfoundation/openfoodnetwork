angular.module('admin.order_cycles').controller "AdminSimpleCreateOrderCycleCtrl", ($scope, OrderCycle, Enterprise, EnterpriseFee) ->
  $scope.enterprises = Enterprise.index (enterprises) =>
    enterprise = enterprises[Object.keys(enterprises)[0]]
    OrderCycle.addSupplier enterprise.id
    OrderCycle.addDistributor enterprise.id
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

    OrderCycle.setExchangeVariants(OrderCycle.order_cycle.incoming_exchanges[0],
      Enterprise.suppliedVariants(enterprise.id), true)

    OrderCycle.order_cycle.coordinator_id = enterprise.id

  $scope.enterprise_fees = EnterpriseFee.index()

  $scope.order_cycle = OrderCycle.order_cycle

  $scope.loaded = ->
    Enterprise.loaded && EnterpriseFee.loaded

  $scope.removeDistributionOfVariant = angular.noop

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
