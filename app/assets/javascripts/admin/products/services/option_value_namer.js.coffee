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
          unit_name = @pluralize(@variant.product.variant_unit_name, value)

        value = parseInt(value, 10) if value == parseInt(value, 10)

      else
        value = unit_name = null

      [value, unit_name]

    pluralize: (unit_name, count) ->
      return unit_name if count == undefined
      unit_key = @unit_key(unit_name)
      return unit_name unless unit_key
      I18n.t(["inflections", unit_key], {count: count, defaultValue: unit_name})

    unit_key: (unit_name) ->
      unless I18n.unit_keys
        I18n.unit_keys = {}
        for key, translations of I18n.t("inflections")
          for quantifier, translation of translations
            I18n.unit_keys[translation.toLowerCase()] = key

      I18n.unit_keys[unit_name.toLowerCase()]

    option_value_value_unit_scaled: ->
      [unit_scale, unit_name] = @scale_for_unit_value()

      value = Math.round((@variant.unit_value / unit_scale) * 100) / 100

      [value, unit_name]

    scale_for_unit_value: ->
      # Find the largest available and compatible unit where unit_value comes
      # to >= 1 when expressed in it.
      # If there is none available where this is true, use the smallest
      # available unit.
      product = @variant.product
      scales = VariantUnitManager.compatibleUnitScales(product.variant_unit_scale, product.variant_unit)
      variantUnitValue = @variant.unit_value

      # sets largestScale = last element in filtered scales array
      [_, ..., largestScale] = (scales.filter (s) -> variantUnitValue / s >= 1)

      if (largestScale)
        [largestScale, VariantUnitManager.getUnitName(largestScale, product.variant_unit)]
      else
        [scales[0], VariantUnitManager.getUnitName(scales[0], product.variant_unit)]
