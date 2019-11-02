angular.module('admin.orderCycles').controller 'AdminOrderCycleOutgoingCtrl', ($scope, $controller, $filter, OrderCycle) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope})

  $scope.view = 'outgoing'

  $scope.productSuppliedToOrderCycle = (product) ->
    OrderCycle.productSuppliedToOrderCycle(product)

  $scope.variantSuppliedToOrderCycle = (variant) ->
    OrderCycle.variantSuppliedToOrderCycle(variant)

  $scope.incomingExchangeVariantsFor = (enterprise_id) ->
    $filter('filterExchangeVariants')(OrderCycle.incomingExchangesVariants(), $scope.order_cycle.visible_variants_for_outgoing_exchanges[enterprise_id])
