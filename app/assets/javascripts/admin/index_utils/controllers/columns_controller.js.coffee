angular.module("admin.indexUtils").controller "ColumnsCtrl", ($scope, Columns) ->
  $scope.columns = Columns.columns
  $scope.predicate = ""
  $scope.reverse = false
