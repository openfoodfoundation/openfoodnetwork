angular.module("admin.products").factory "OptionValueNamer", ->
  class OptionValueNamer
    @getUnitName: (scale, unitType) ->
      unitNames =
        'weight': {1.0: 'g', 1000.0: 'kg', 1000000.0: 'T'}
        'volume': {0.001: 'mL', 1.0: 'L',  1000.0: 'kL'}
      unitNames[unitType][scale]

    @unitScales: (unitType) ->
      unitScales =
        'weight': [1.0, 1000.0, 1000000.0]
        'volume': [0.001, 1.0, 1000.0]
      unitScales[unitType]

    @variant_unit_options: [
      ["Weight (g)", "weight_1"],
      ["Weight (kg)", "weight_1000"],
      ["Weight (T)", "weight_1000000"],
      ["Volume (mL)", "volume_0.001"],
      ["Volume (L)", "volume_1"],
      ["Volume (kL)", "volume_1000"],
      ["Items", "items"]
    ]


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
      units =
        'weight':
          1.0: 'g'
          1000.0: 'kg'
          1000000.0: 'T'
        'volume':
          0.001: 'mL'
          1.0: 'L'
          1000.0: 'kL'

      # Find the largest available unit where unit_value comes to >= 1 when expressed in it.
      # If there is none available where this is true, use the smallest available unit.
      unit = ([scale, unit_name] for scale, unit_name of units[@variant.product.variant_unit] when @variant.unit_value / scale >= 1).reduce (unit, [scale, unit_name]) ->
        if (unit && scale > unit[0]) || !unit?
          [scale, unit_name]
        else
          unit
      , null
      if !unit?
        unit = ([scale, unit_name] for scale, unit_name of units[@variant.product.variant_unit]).reduce (unit, [scale, unit_name]) ->
          if scale < unit[0] then [scale, unit_name] else unit
        , [Infinity,""]

      unit
