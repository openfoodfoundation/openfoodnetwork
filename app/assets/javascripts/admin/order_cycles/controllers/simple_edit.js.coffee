angular.module('admin.order_cycles').controller "AdminSimpleEditOrderCycleCtrl", ($scope, $location, OrderCycle, Enterprise, EnterpriseFee) ->
  $scope.enterprises = Enterprise.index()
  $scope.enterprise_fees = EnterpriseFee.index()
  $scope.order_cycle = OrderCycle.load $scope.orderCycleId(), (order_cycle) =>
    $scope.init()

  $scope.orderCycleId = ->
    $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]

  $scope.init = ->
    $scope.outgoing_exchange = OrderCycle.order_cycle.outgoing_exchanges[0]

  $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
    EnterpriseFee.forEnterprise(parseInt(enterprise_id))
