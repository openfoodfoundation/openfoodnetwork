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
    return "custom" unless scales = scales_for_variant_unit(ignore_available_units: true)

    variant_scale = @variant.variant_unit_scale&.to_f
    return "custom" unless variant_scale.present? && variant_scale.positive?

    scales[variant_scale]['system']
  end

  # @returns enumerable with label and value for select
  def self.variant_unit_options
    available_units_sorted.flat_map do |measurement, measurement_info|
      measurement_info.filter_map do |scale, unit_info|
        # Our code is based upon English based number formatting
        # Some language locales like +hu+ uses a comma(,) for decimal separator
        # While in English, decimal separator is represented by a period.
        # e.g. en: 0.001, hu: 0,001
        # Hence the results become "weight_0,001" for hu while or code recognizes "weight_0.001"
        scale_clean =
          ActiveSupport::NumberHelper.number_to_rounded(scale, precision: nil, significant: false,
                                                               strip_insignificant_zeros: true,
                                                               locale: :en)
        [
          "#{I18n.t(measurement)} (#{unit_info['name']})", # Label (eg "Weight (g)")
          "#{measurement}_#{scale_clean}", # Scale ID (eg "weight_1")
        ]
      end
    end <<
      [
        I18n.t('items'),
        'items'
      ]
  end

  def self.available_units
    CurrentConfig.get(:available_units).split(",")
  end

  def self.available_units_sorted
    self::UNITS.transform_values do |measurement_info|
      # Filter to only include available units
      measurement_info.filter do |_scale, unit_info|
        available_units.include?(unit_info['name'])
      end.
        # Remove duplicates by name
        uniq do |_scale, unit_info|
        unit_info['name']
      end.
        # Sort by unit number
        sort.to_h
    end
  end

  private

  UNITS = {
    'weight' => {
      0.001 => { 'name' => 'mg', 'system' => 'metric' },
      1.0 => { 'name' => 'g', 'system' => 'metric' },
      1000.0 => { 'name' => 'kg', 'system' => 'metric' },
      1_000_000.0 => { 'name' => 'T', 'system' => 'metric' },

      28.35 => { 'name' => 'oz', 'system' => 'imperial' },
      28.349523125 => { 'name' => 'oz', 'system' => 'imperial' },
      453.6 => { 'name' => 'lb', 'system' => 'imperial' },
      453.59237 => { 'name' => 'lb', 'system' => 'imperial' },
    },
    'volume' => {
      0.001 => { 'name' => 'mL', 'system' => 'metric' },
      0.01 => { 'name' => 'cL', 'system' => 'metric' },
      0.1 => { 'name' => 'dL', 'system' => 'metric' },
      1.0 => { 'name' => 'L', 'system' => 'metric' },
      1000.0 => { 'name' => 'kL', 'system' => 'metric' },

      4.54609 => { 'name' => 'gal', 'system' => 'imperial' },
    }
  }.freeze

  def scales_for_variant_unit(ignore_available_units: false)
    return @units[@variant.variant_unit] if ignore_available_units

    @units[@variant.variant_unit]&.reject { |_scale, unit_info|
      self.class.available_units.exclude?(unit_info['name'])
    }
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
