angular.module("admin.products").factory "VariantUnitManager", (availableUnits) ->
  class VariantUnitManager
    @units:
      'weight':
        1.0:
          name: 'g'
          system: 'metric'
        1000.0:
          name: 'kg'
          system: 'metric'
        1000000.0:
          name: 'T'
          system: 'metric'
        453.6:
          name: 'lb'
          system: 'imperial'
        28.35:
          name: 'oz'
          system: 'imperial'
      'volume':
        0.001:
          name: 'mL'
          system: 'metric'
        1.0:
          name: 'L'
          system: 'metric'
        1000.0:
          name: 'kL'
          system: 'metric'
      'items':
        1:
          name: 'items'

    @variantUnitOptions: ->
      available = availableUnits.split(",")
      options = for unit_type, _ of @units
        for scale in @unitScales(unit_type, available)
          name = @getUnitName(scale, unit_type)
          ["#{I18n.t(unit_type)} (#{name})", @getUnitWithScale(unit_type, scale)]
      options.push [[I18n.t('items'), 'items']]
      options = [].concat options...

    @getUnitWithScale: (unit_type, scale) ->
      "#{unit_type}_#{scale}"

    @getUnitName: (scale, unitType) ->
      if @units[unitType][scale]
        @units[unitType][scale]['name']
      else
        ''

    @unitScales: (unitType, availableUnits = null) ->
      scales = Object.keys(@units[unitType])
      if availableUnits
        scales = scales.filter (scale) ->
          availableUnits.includes(VariantUnitManager.getUnitName(scale, unitType))

      (parseFloat(scale) for scale in scales).sort (a, b) ->
         a - b

    @compatibleUnitScales: (scale, unitType) ->
      scaleSystem = @units[unitType][scale]['system']
      (parseFloat(scale) for scale, scaleInfo of @units[unitType] when scaleInfo['system'] == scaleSystem).sort (a, b) ->
         a - b

    @systemOfMeasurement: (scale, unitType) ->
      if @units[unitType][scale]
        @units[unitType][scale]['system']
      else
        'custom'
