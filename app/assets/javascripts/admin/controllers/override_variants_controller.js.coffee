angular.module("ofn.admin").controller "AdminOverrideVariantsCtrl", ($scope, hubs) ->
  $scope.hubs = hubs
  $scope.hub = null

  $scope.selectHub = ->
    $scope.hub = (hub for hub in hubs when hub.id == $scope.hub_id)[0]