angular.module("admin.products")
  .controller "unitsCtrl", ($scope, VariantUnitManager, OptionValueNamer, UnitPrices, PriceParser) ->
    $scope.product = { master: {} }
    $scope.product.master.product = $scope.product
    $scope.placeholder_text = ""

    $scope.$watchCollection '[product.variant_unit_with_scale, product.master.unit_value_with_description, product.price, product.variant_unit_name]', ->
      $scope.processVariantUnitWithScale()
      $scope.processUnitValueWithDescription()
      $scope.processUnitPrice()
      $scope.placeholder_text = new OptionValueNamer($scope.product.master).name() if $scope.product.variant_unit_scale

    $scope.variant_unit_options = VariantUnitManager.variantUnitOptions()

    $scope.processVariantUnitWithScale = ->
      if $scope.product.variant_unit_with_scale
        match = $scope.product.variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/)
        if match
          $scope.product.variant_unit = match[1]
          $scope.product.variant_unit_scale = parseFloat(match[2])
        else
          $scope.product.variant_unit = $scope.product.variant_unit_with_scale
          $scope.product.variant_unit_scale = null
      else if $scope.product.variant_unit
        # Preserves variant_unit_with_scale when form validation fails and reload triggers
        if $scope.product.variant_unit_scale
          $scope.product.variant_unit_with_scale = VariantUnitManager.getUnitWithScale(
            $scope.product.variant_unit, parseFloat($scope.product.variant_unit_scale)
          )
        else
          $scope.product.variant_unit_with_scale = $scope.product.variant_unit
      else
        $scope.product.variant_unit = $scope.product.variant_unit_scale = null

    $scope.processUnitValueWithDescription = ->
      if $scope.product.master.hasOwnProperty("unit_value_with_description")
        match = $scope.product.master.unit_value_with_description.match(/^([\d\.,]+(?= *|$)|)( *)(.*)$/)
        if match
          $scope.product.master.unit_value  = PriceParser.parse(match[1])
          $scope.product.master.unit_value  = null if isNaN($scope.product.master.unit_value)
          $scope.product.master.unit_value = window.bigDecimal.multiply($scope.product.master.unit_value, $scope.product.variant_unit_scale, 2) if $scope.product.master.unit_value && $scope.product.variant_unit_scale
          $scope.product.master.unit_description = match[3]
      else
        value = $scope.product.master.unit_value
        value = window.bigDecimal.divide(value, $scope.product.variant_unit_scale, 2) if $scope.product.master.unit_value && $scope.product.variant_unit_scale
        $scope.product.master.unit_value_with_description = value + " " + $scope.product.master.unit_description

    $scope.processUnitPrice = ->
      price = $scope.product.price
      scale = $scope.product.variant_unit_scale
      unit_type = $scope.product.variant_unit
      unit_value = $scope.product.master.unit_value
      variant_unit_name = $scope.product.variant_unit_name
      $scope.unit_price = UnitPrices.displayableUnitPrice(price, scale, unit_type, unit_value, variant_unit_name)

    $scope.hasVariants = (product) ->
      Object.keys(product.variants).length > 0

    $scope.hasUnit = (product) ->
      product.variant_unit_with_scale?
