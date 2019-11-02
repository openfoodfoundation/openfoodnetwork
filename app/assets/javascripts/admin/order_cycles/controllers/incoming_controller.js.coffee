angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $controller, Enterprise) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope})

  $scope.view = 'incoming'

  $scope.enterpriseTotalVariants = (enterprise) ->
    Enterprise.totalVariants(enterprise)
