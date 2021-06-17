angular.module("admin.products").factory "UnitPrices", (VariantUnitManager, localizeCurrencyFilter, PriceParser) ->
  class UnitPrices
    @displayableUnitPrice: (price, scale, unit_type, unit_value, variant_unit_name) ->
      price = PriceParser.parse(price)
      if price && !isNaN(price) && unit_type && unit_value
        value = localizeCurrencyFilter(UnitPrices.price(price, scale, unit_type, unit_value, variant_unit_name))
        unit = UnitPrices.unit(scale, unit_type, variant_unit_name)
        return value + " / " + unit
      return null

    @price: (price, scale, unit_type, unit_value) ->
      price / @denominator(scale, unit_type, unit_value)

    @denominator: (scale, unit_type, unit_value) ->
      unit = @unit(scale, unit_type)
      if unit == "lb"
        unit_value / 453.6
      else if unit == "kg"
        unit_value / 1000
      else
        unit_value

    @unit: (scale, unit_type, variant_unit_name = '') ->
      if variant_unit_name.length > 0
        variant_unit_name
      else if unit_type == "items"
        "item"
      else if VariantUnitManager.systemOfMeasurement(scale, unit_type) == "imperial"
        "lb"
      else if unit_type == "weight"
        "kg"
      else if unit_type == "volume"
        "L"
