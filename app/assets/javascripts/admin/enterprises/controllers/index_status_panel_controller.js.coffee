angular.module("admin.enterprises").controller 'indexStatusPanelCtrl', ($scope, $filter) ->
  $scope.issues = $scope.object.issues
  $scope.warnings = $scope.object.warnings
