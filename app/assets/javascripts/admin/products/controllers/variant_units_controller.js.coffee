angular.module("admin.products").controller "variantUnitsCtrl", ($scope, VariantUnitManager, $timeout) ->

  $scope.unitName = (scale, type) ->
    VariantUnitManager.getUnitName(scale, type)

  $scope.scale = angular.element('#product_variant_unit_scale').val()

  $scope.updateValue = ->
    unit_value_human = angular.element('#unit_value_human').val()
    $scope.unit_value = unit_value_human * $scope.scale

  variant_unit_value = angular.element('#variant_unit_value').val()
  $scope.unit_value_human = variant_unit_value / $scope.scale
  $timeout -> $scope.updateValue()
