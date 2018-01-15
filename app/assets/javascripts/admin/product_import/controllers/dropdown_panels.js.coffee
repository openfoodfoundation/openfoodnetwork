angular.module("admin.productImport").controller "DropdownPanelsCtrl", ($scope) ->
  $scope.active = false

  $scope.togglePanel = ->
    $scope.active = !$scope.active
