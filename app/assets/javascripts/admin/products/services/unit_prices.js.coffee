angular.module("admin.products").factory "UnitPrices", (VariantUnitManager) ->
  class UnitPrices
    @price: (price, scale, unit_type, unit_value) ->
      price / @denominator(unit_value, variant_unit)

    @denominator: (scale, unit_type, unit_value) ->
      unit = @unit(scale, unit_type)
      if unit == "lb"
        unit_value / 453.6
      else if unit == "kg"
        unit_value / 1000
      else
        unit_value

    @unit: (scale, unit_type, variant_unit_name = '') ->
      if VariantUnitManager.systemOfMeasurement(scale, unit_type) == "imperial"
        "lb"
      else if unit_type == "weight"
        "kg"
      else if unit_type == "volume"
        "L"
      else if variant_unit_name.length > 0
        variant_unit_name
      else
        "item"
