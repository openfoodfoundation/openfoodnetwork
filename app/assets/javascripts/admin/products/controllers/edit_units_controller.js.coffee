angular.module("admin.products").controller "editUnitsCtrl", ($scope, VariantUnitManager) ->

  $scope.product =
    variant_unit: angular.element('#variant_unit').val()
    variant_unit_scale: angular.element('#variant_unit_scale').val()

  $scope.variant_unit_options = VariantUnitManager.variantUnitOptions()

  if $scope.product.variant_unit == 'items'
    $scope.variant_unit_with_scale = 'items'
  else
    $scope.variant_unit_with_scale = $scope.product.variant_unit + '_' + $scope.product.variant_unit_scale.replace(/\.0$/, '');

  $scope.setFields = ->
    if $scope.variant_unit_with_scale == 'items'
      variant_unit = 'items'
      variant_unit_scale = null
    else
      options = $scope.variant_unit_with_scale.split('_')
      variant_unit = options[0]
      variant_unit_scale = options[1]

    $scope.product.variant_unit = variant_unit
    $scope.product.variant_unit_scale = variant_unit_scale
