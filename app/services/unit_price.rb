# frozen_string_literal: true

class UnitPrice
  def initialize(variant)
    @variant = variant
    @product = variant.product
  end

  def denominator
    return 1 if @variant.unit_value.zero?

    # catches any case where unit is not kg, lb, or L.
    return @variant.unit_value if @product&.variant_unit == "items"

    case unit
    when "lb"
      @variant.unit_value / 453.6
    when "kg"
      @variant.unit_value / 1000
    else # Liters
      @variant.unit_value
    end
  end

  def unit
    return I18n.t("item") if @variant.unit_value.zero?
    return "lb" if WeightsAndMeasures.new(@variant).system == "imperial"

    case @product&.variant_unit
    when "weight"
      "kg"
    when "volume"
      "L"
    else
      @product.variant_unit_name.presence || I18n.t("item")
    end
  end
end
