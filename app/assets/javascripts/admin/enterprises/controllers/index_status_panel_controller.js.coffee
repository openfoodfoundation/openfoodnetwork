angular.module("admin.enterprises").controller 'indexStatusPanelCtrl', ($scope, $filter) ->
  $scope.issues = $filter('filter')($scope.object.issues, {resolved: false })
  $scope.warnings = $filter('filter')($scope.object.warnings, {resolved: false})
