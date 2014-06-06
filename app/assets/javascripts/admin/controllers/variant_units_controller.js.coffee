angular.module("ofn.admin")
  .controller "VariantUnitsCtrl", ($scope, optionValueNamer) ->
    $scope.$watchCollection '[variant.unit_value_with_description, product.variant_unit_name, product.variant_unit_with_scale]', ->
      [variant_unit, variant_unit_scale] = $scope.productUnitProperties()
      [unit_value, unit_description] = $scope.variantUnitProperties(variant_unit_scale)
      variant_object = 
        unit_value: unit_value
        unit_description: unit_description
        product:
          variant_unit_scale: variant_unit_scale
          variant_unit: variant_unit
          variant_unit_name: $scope.product.variant_unit_name
        
      $scope.variant.options_text = new optionValueNamer(variant_object).name()

    $scope.productUnitProperties = ->
      # get relevant product properties
      if $scope.product.variant_unit_with_scale
        match = $scope.product.variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/)
        if match
          variant_unit = match[1]
          variant_unit_scale = parseFloat(match[2])
        else
          variant_unit = $scope.product.variant_unit_with_scale
          variant_unit_scale = null
      else
        variant_unit = variant_unit_scale = null

      [variant_unit, variant_unit_scale]

    $scope.variantUnitProperties = (variant_unit_scale)->
      # get relevant variant properties
      if $scope.variant.hasOwnProperty("unit_value_with_description")
        match = $scope.variant.unit_value_with_description.match(/^([\d\.]+(?= |$)|)( |)(.*)$/)
        if match
          unit_value  = parseFloat(match[1])
          unit_value  = null if isNaN(unit_value)
          unit_value *= variant_unit_scale if unit_value && variant_unit_scale
          unit_description = match[3]
      [unit_value, unit_description]
      
        