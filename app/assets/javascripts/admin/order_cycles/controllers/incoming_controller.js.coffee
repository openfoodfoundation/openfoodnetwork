angular.module('admin.orderCycles').controller 'AdminOrderCycleIncomingCtrl', ($scope, $controller) ->
  $controller('AdminEditOrderCycleCtrl', {$scope: $scope})
  $scope.view = 'incoming'
