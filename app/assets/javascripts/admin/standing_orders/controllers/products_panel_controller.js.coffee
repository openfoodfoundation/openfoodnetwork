angular.module("admin.standingOrders").controller "ProductsPanelController", ($scope, StandingOrders, StatusMessage) ->
  $scope.standingOrder = $scope.object
  $scope.distributor_id = $scope.standingOrder.shop_id
  $scope.saving = false

  $scope.saved = ->
    pristine = StandingOrders.pristineByID[$scope.standingOrder.id].standing_line_items
    return false unless angular.equals($scope.standingOrder.standing_line_items, pristine)
    true

  $scope.save = ->
    $scope.saving = true
    StatusMessage.display 'progress', 'Saving...'
    $scope.standingOrder.update().then (response) ->
      $scope.saving = false
      StatusMessage.display 'success', 'Saved'
    , (response) ->
      $scope.saving = false
      if response.data?.errors?
        keys = Object.keys(response.data.errors)
        StatusMessage.display 'failure', response.data.errors[keys[0]][0]
      else
        StatusMessage.display 'success', 'Saved'
