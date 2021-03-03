# frozen_string_literal: true

module VariantUnits
  class UnitPrices
    def initialize(variant)
      @variant = variant
      @product = variant.product
    end

    def denominator
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
      return "lb" if VariantUnits::WeightsAndMeasures.new(@variant).
        system_of_measurement == "imperial"

      case @product&.variant_unit
      when "weight"
        "kg"
      when "volume"
        "L"
      else
        @product.variant_unit_name.presence || "item"
      end
    end
  end
end
