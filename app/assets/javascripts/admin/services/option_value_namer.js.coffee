angular.module("admin.products").factory "OptionValueNamer", (VariantUnitManager) ->
  class OptionValueNamer
    constructor: (@variant) ->

    name: ->
      [value, unit] = @option_value_value_unit()
      separator = if @value_scaled() then '' else ' '

      name_fields = []
      name_fields.push "#{value}#{separator}#{unit}" if value? && unit?
      name_fields.push @variant.unit_description if @variant.unit_description?
      name_fields.join ' '

    value_scaled: ->
      @variant.product.variant_unit_scale?

    option_value_value_unit: ->
      if @variant.unit_value?
        if @variant.product.variant_unit in ["weight", "volume"]
          [value, unit_name] = @option_value_value_unit_scaled()

        else
          value = @variant.unit_value
          unit_name = @variant.product.variant_unit_name
          # TODO needs to add pluralize to line below
          # unit_name = unit_name if value > 1

        value = parseInt(value, 10) if value == parseInt(value, 10)

      else
        value = unit_name = null

      [value, unit_name]

    option_value_value_unit_scaled: ->
      [unit_scale, unit_name] = @scale_for_unit_value()

      value = @variant.unit_value / unit_scale

      [value, unit_name]

    scale_for_unit_value: ->
      # Find the largest available unit where unit_value comes to >= 1 when expressed in it.
      # If there is none available where this is true, use the smallest available unit.
      unit = ([scale, unit_name] for scale, unit_name of VariantUnitManager.unitNames[@variant.product.variant_unit] when @variant.unit_value / scale >= 1).reduce (unit, [scale, unit_name]) ->
        if (unit && scale > unit[0]) || !unit?
          [scale, unit_name]
        else
          unit
      , null
      if !unit?
        unit = ([scale, unit_name] for scale, unit_name of VariantUnitManager.unitNames[@variant.product.variant_unit]).reduce (unit, [scale, unit_name]) ->
          if scale < unit[0] then [scale, unit_name] else unit
        , [Infinity,""]

      unit
