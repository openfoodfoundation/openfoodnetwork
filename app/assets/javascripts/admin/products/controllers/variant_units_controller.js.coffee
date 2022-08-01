angular.module("admin.products").controller "variantUnitsCtrl", ($scope, VariantUnitManager, $timeout, UnitPrices, PriceParser) ->

  $scope.unitName = (scale, type) ->
    VariantUnitManager.getUnitName(scale, type)

  $scope.$watchCollection "[unit_value_human, variant.price]", ->
    $scope.processUnitPrice()
  
  $scope.processUnitPrice = ->
    if ($scope.variant)
      price = $scope.variant.price
      scale = $scope.scale
      unit_type = angular.element("#product_variant_unit").val()
      if (unit_type != "items")
        $scope.updateValue()
        unit_value = $scope.unit_value
      else 
        unit_value = 1
      variant_unit_name = angular.element("#product_variant_unit_name").val()
      $scope.unit_price = UnitPrices.displayableUnitPrice(price, scale, unit_type, unit_value, variant_unit_name)

  $scope.scale = angular.element('#product_variant_unit_scale').val()

  $scope.updateValue = ->
    unit_value_human = angular.element('#unit_value_human').val()
    $scope.unit_value = bigDecimal.multiply(PriceParser.parse(unit_value_human), $scope.scale, 2)

  variant_unit_value = angular.element('#variant_unit_value').val()
  $scope.unit_value_human = parseFloat(bigDecimal.divide(variant_unit_value, $scope.scale, 2))

  $timeout -> $scope.processUnitPrice()
  $timeout -> $scope.updateValue()
