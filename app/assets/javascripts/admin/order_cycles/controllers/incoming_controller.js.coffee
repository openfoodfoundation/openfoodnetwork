angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $controller, $location, Enterprise, ocInstance) ->
  $controller('AdminOrderCycleExchangesCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

  $scope.enterpriseTotalVariants = (enterprise) ->
    Enterprise.totalVariants(enterprise)
