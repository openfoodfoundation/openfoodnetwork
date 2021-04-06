angular.module("admin.products").factory "UnitPrices", (VariantUnitManager, localizeCurrencyFilter) ->
  class UnitPrices
    @displayableUnitPrice: (price, scale, unit_type, unit_value, variant_unit_name) ->
      if price && !isNaN(price) && unit_type && unit_value
        value = localizeCurrencyFilter(UnitPrices.price(price, scale, unit_type, unit_value, variant_unit_name))
        unit = UnitPrices.unit(scale, unit_type, variant_unit_name, unit_value)
        return value + " / " + unit
      return null

    @price: (price, scale, unit_type, unit_value) ->
      price / @denominator(scale, unit_type, unit_value)

    @denominator: (scale, unit_type, unit_value) ->
      unit = @unit(scale, unit_type)
      if unit_value == 0
        1
      else if unit == "lb"
        unit_value / 453.6
      else if unit == "kg"
        unit_value / 1000
      else
        unit_value

    @unit: (scale, unit_type, variant_unit_name = '', unit_value = null) ->
      if unit_value == 0 || unit_type == "items"
        "item"
      else if variant_unit_name.length > 0
        variant_unit_name
      else if VariantUnitManager.systemOfMeasurement(scale, unit_type) == "imperial"
        "lb"
      else if unit_type == "weight"
        "kg"
      else if unit_type == "volume"
        "L"
