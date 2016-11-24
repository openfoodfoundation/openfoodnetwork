angular.module("admin.standingOrders").controller "ProductsPanelController", ($scope) ->
  $scope.standingOrder = $scope.object
  $scope.distributor_id = $scope.standingOrder.shop.id
