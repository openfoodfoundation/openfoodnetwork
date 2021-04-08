# frozen_string_literal: true

class WeightsAndMeasures
  def initialize(variant)
    @variant = variant
    @units = UNITS
  end

  def scale_for_unit_value
    largest_unit = find_largest_unit(scales_for_variant_unit, system)
    return [nil, nil] unless largest_unit

    [largest_unit[0], largest_unit[1]["name"]]
  end

  def system
    return "custom" unless scales = scales_for_variant_unit
    return "custom" unless product_scale = @variant.product.variant_unit_scale

    scales[product_scale.to_f]['system']
  end

  private

  UNITS = {
    'weight' => {
      1.0 => { 'name' => 'g', 'system' => 'metric' },
      28.35 => { 'name' => 'oz', 'system' => 'imperial' },
      453.6 => { 'name' => 'lb', 'system' => 'imperial' },
      1000.0 => { 'name' => 'kg', 'system' => 'metric' },
      1_000_000.0 => { 'name' => 'T', 'system' => 'metric' }
    },
    'volume' => {
      0.001 => { 'name' => 'mL', 'system' => 'metric' },
      1.0 => { 'name' => 'L', 'system' => 'metric' },
      1000.0 => { 'name' => 'kL', 'system' => 'metric' }
    }
  }.freeze

  def scales_for_variant_unit
    @units[@variant.product.variant_unit]
  end

  # Find the largest available and compatible unit where unit_value comes
  #   to >= 1 when expressed in it.
  # If there is none available where this is true, use the smallest available unit.
  def find_largest_unit(scales, product_scale_system)
    return nil unless scales

    largest_unit = scales.select { |scale, unit_info|
      unit_info['system'] == product_scale_system &&
        @variant.unit_value / scale >= 1
    }.max
    return scales.first if largest_unit.nil?

    largest_unit
  end
end
