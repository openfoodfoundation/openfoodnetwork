angular.module("admin.dropdown").controller "ColumnsDropdownCtrl", ($scope, Columns) ->
  $scope.columns = Columns.columns
  $scope.toggle = Columns.toggleColumn
  $scope.saveColumnPreferences = Columns.savePreferences
  $scope.saved = Columns.preferencesSaved
