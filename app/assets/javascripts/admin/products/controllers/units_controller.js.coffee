angular.module("admin.products")
  .controller "unitsCtrl", ($scope, VariantUnitManager, OptionValueNamer) ->
    $scope.product = { master: {} }
    $scope.product.master.product = $scope.product
    $scope.placeholder_text = ""

    $scope.$watchCollection '[product.variant_unit_with_scale, product.master.unit_value_with_description]', ->
      $scope.processVariantUnitWithScale()
      $scope.processUnitValueWithDescription()
      $scope.placeholder_text = new OptionValueNamer($scope.product.master).name()

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
      else
        $scope.product.variant_unit = $scope.product.variant_unit || angular.element(document.querySelector('#product_variant_unit')).val() || null
        $scope.product.variant_unit_scale = $scope.product.variant_unit_scale || parseFloat(angular.element(document.querySelector('#product_variant_unit_scale')).val()) || null
        $scope.product.variant_unit_scale = null if isNaN($scope.product.variant_unit_scale)
        $scope.product.variant_unit_with_scale = $scope.product.variant_unit + '_' + $scope.product.variant_unit_scale if !!$scope.product.variant_unit
        setTimeout(->
          $('#product_variant_unit_with_scale').trigger('change')
        , 1000)

    $scope.processUnitValueWithDescription = ->
      if $scope.product.master.hasOwnProperty("unit_value_with_description") && !!$scope.product.master.unit_value_with_description
        match = $scope.product.master.unit_value_with_description.match(/^([\d\.]+(?= *|$)|)( *)(.*)$/)
        if match
          $scope.product.master.unit_value  = parseFloat(match[1])
          $scope.product.master.unit_value  = null if isNaN($scope.product.master.unit_value)
          $scope.product.master.unit_value *= $scope.product.variant_unit_scale if $scope.product.master.unit_value && $scope.product.variant_unit_scale
          $scope.product.master.unit_description = match[3]
      else
        $scope.product.master.unit_value = parseFloat(angular.element('#product_unit_value').val())
        $scope.product.master.unit_value  = null if isNaN($scope.product.master.unit_value)
        $scope.product.master.unit_value_with_description = '' + $scope.product.master.unit_value / $scope.product.variant_unit_scale
        $scope.product.master.unit_value_with_description = null if isNaN($scope.product.master.unit_value_with_description)
        $scope.product.master.unit_description = angular.element('#product_unit_description').val() if $scope.product.master.unit_value

    $scope.hasVariants = (product) ->
      Object.keys(product.variants).length > 0

    $scope.hasUnit = (product) ->
      product.variant_unit_with_scale?
