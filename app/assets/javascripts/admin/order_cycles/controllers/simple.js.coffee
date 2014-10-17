angular.module('admin.order_cycles').controller "AdminSimpleCreateOrderCycleCtrl", ($scope, OrderCycle, Enterprise, EnterpriseFee) ->
  $scope.enterprises = Enterprise.index (enterprises) =>
    enterprise = enterprises[Object.keys(enterprises)[0]]
    OrderCycle.addSupplier enterprise.id
    OrderCycle.addDistributor enterprise.id

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

  $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
    EnterpriseFee.forEnterprise(parseInt(enterprise_id))

