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
        for scale in @unitScales(unit_type)
          name = @getUnitName(scale, unit_type)
          ["#{I18n.t(unit_type)} (#{name})", "#{unit_type}_#{scale}"]
      options.push [[I18n.t('items'), 'items']]
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
