angular.module("admin.productImport").controller "ImportFeedbackCtrl", ($scope) ->

  $scope.count = (items) ->
    total = 0
    angular.forEach items, (item) ->
      total++
    total

  $scope.attribute_invalid = (attribute, line_number) ->
    $scope.entries[line_number]['errors'][attribute] != undefined

  $scope.ignore_fields = ['variant_unit', 'variant_unit_scale', 'unit_description']
