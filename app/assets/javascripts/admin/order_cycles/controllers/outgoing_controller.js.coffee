angular.module('admin.orderCycles').controller 'AdminOrderCycleOutgoingCtrl', ($scope, $controller) ->
  $controller('AdminEditOrderCycleCtrl', {$scope: $scope})
  $scope.view = 'outgoing'
