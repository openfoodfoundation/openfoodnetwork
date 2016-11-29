angular.module("admin.standingOrders").controller "ProductsPanelController", ($scope, StandingOrders) ->
  $scope.standingOrder = $scope.object
  $scope.distributor_id = $scope.standingOrder.shop_id
  $scope.saving = false

  $scope.saved = ->
    pristine = StandingOrders.pristineByID[$scope.standingOrder.id].standing_line_items
    return false unless angular.equals($scope.standingOrder.standing_line_items, pristine)
    true

  $scope.save = ->
    $scope.saving = true
    $scope.standingOrder.update().then ->
      $scope.saving = false
    , ->
      $scope.saving = false
