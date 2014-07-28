angular.module("admin.products").factory "VariantUnitManager", ->
  class VariantUnitManager
    @unitNames:
      'weight':
        1.0: 'g'
        1000.0: 'kg'
        1000000.0: 'T'
      'volume':
        0.001: 'mL'
        1.0: 'L'
        1000.0: 'kL'

    @variantUnitOptions: ->
      options = for unit_type, scale_with_name of @unitNames
        unit_type_cap = unit_type[0].toUpperCase() + unit_type[1..-1]
        for scale in @unitScales(unit_type)
          name = @getUnitName(scale, unit_type)
          ["#{unit_type_cap} (#{name})", "#{unit_type}_#{scale}"]
      options.push [['Items', 'items']]
      [].concat options...

    @getScale: (value, unitType) ->
      scaledValue = null
      validScales = []
      unitScales = VariantUnitManager.unitScales(unitType)

      validScales.unshift scale for scale in unitScales when value/scale >= 1
      if validScales.length > 0
        validScales[0]
      else
        unitScales[0]

    @getUnitName: (scale, unitType) ->
      @unitNames[unitType][scale]

    @unitScales: (unitType) ->
      (parseFloat(scale) for scale in Object.keys(@unitNames[unitType])).sort()
