angular.module("ofn.admin").directive "ofnDisplayAs", (OptionValueNamer) ->
  link: (scope, element, attrs) ->

    scope.$watchCollection ->
      return [
        scope.$eval(attrs.ofnDisplayAs).unit_value_with_description
        scope.product.variant_unit_name
        scope.product.variant_unit_with_scale
      ]
    , ->
      [variant_unit, variant_unit_scale] = productUnitProperties()
      [unit_value, unit_description] = variantUnitProperties(variant_unit_scale)
      variant_object = 
        unit_value: unit_value
        unit_description: unit_description
        product:
          variant_unit_scale: variant_unit_scale
          variant_unit: variant_unit
          variant_unit_name: scope.product.variant_unit_name

      scope.placeholder_text = new OptionValueNamer(variant_object).name()

    productUnitProperties = ->
      # get relevant product properties
      if scope.product.variant_unit_with_scale?
        match = scope.product.variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/)
        if match
          variant_unit = match[1]
          variant_unit_scale = parseFloat(match[2])
        else
          variant_unit = scope.product.variant_unit_with_scale
          variant_unit_scale = null
      else
        variant_unit = variant_unit_scale = null

      [variant_unit, variant_unit_scale]

    variantUnitProperties = (variant_unit_scale)->
      # get relevant variant properties
      variant = scope.$eval(attrs.ofnDisplayAs) # Like this so we can switch between 'master' and 'variant'
      if variant.unit_value_with_description?
        match = variant.unit_value_with_description.match(/^([\d\.]+(?= |$)|)( |)(.*)$/)
        if match
          unit_value  = parseFloat(match[1])
          unit_value  = null if isNaN(unit_value)
          unit_value *= variant_unit_scale if unit_value && variant_unit_scale
          unit_description = match[3]
      [unit_value, unit_description]