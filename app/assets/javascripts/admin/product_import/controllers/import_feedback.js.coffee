angular.module("ofn.admin").controller "ImportFeedbackCtrl", ($scope, productImportData) ->
  $scope.entries = productImportData

  $scope.count = (items) ->
    total = 0
    angular.forEach items, (item) ->
      total++
    total

  $scope.attribute_invalid = (attribute, line_number) ->
    $scope.entries[line_number]['errors'][attribute] != undefined