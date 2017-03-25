angular.module("ofn.admin").controller "DropdownPanelsCtrl", ($scope) ->
  $scope.active = false

  $scope.togglePanel = ->
    $scope.active = !$scope.active
