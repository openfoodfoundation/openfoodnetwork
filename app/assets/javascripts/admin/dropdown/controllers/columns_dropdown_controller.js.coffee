angular.module("admin.dropdown").controller "ColumnsDropdownCtrl", ($scope, Columns) ->
  $scope.columns = Columns.columns
  $scope.toggle = Columns.toggleColumn
  $scope.saved = Columns.preferencesSaved
  $scope.saving = false

  $scope.saveColumnPreferences = (action_name) ->
    $scope.saving = true
    Columns.savePreferences(action_name).then ->
      $scope.saving = false
