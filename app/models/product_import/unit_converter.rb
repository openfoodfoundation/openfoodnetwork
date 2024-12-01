# frozen_string_literal: true

# This class handles conversion of human-readable unit weights for products/variants into
# the non-human-readable format needed by the database. The table below shows how fields
# from a spreadsheet (left) become database fields (right):
#
# units  unit_type  variant_unit_name   ->    unit_value  variant_unit_scale   variant_unit
# 250      ml          nil              ->       0.25        0.001               volume
# 50       g           nil              ->       50          1                   weight
# 2        kg          nil              ->       2000        1000                weight
# 1        nil         bunches          ->       1           nil                 items

module ProductImport
  class UnitConverter
    def initialize(attrs)
      @attrs = attrs
      convert_custom_unit_fields
    end

    def converted_attributes
      @attrs
    end

    private

    def convert_custom_unit_fields
      init_unit_values

      assign_weight_or_volume_attributes if units_and_unit_type_present?
      assign_item_attributes if units_and_variant_unit_name_present?
    end

    def unit_scales
      {
        'mg' => { scale: 0.001, unit: 'weight' },
        'g' => { scale: 1, unit: 'weight' },
        'kg' => { scale: 1000, unit: 'weight' },
        'oz' => { scale: 28.35, unit: 'weight' },
        'lb' => { scale: 453.6, unit: 'weight' },
        't' => { scale: 1_000_000, unit: 'weight' },
        'ml' => { scale: 0.001, unit: 'volume' },
        'cl' => { scale: 0.01, unit: 'volume' },
        'dl' => { scale: 0.1, unit: 'volume' },
        'l' => { scale: 1, unit: 'volume' },
        'kl' => { scale: 1000, unit: 'volume' },
        'gal' => { scale: 4.54609, unit: 'volume' },
      }
    end

    def init_unit_values
      @attrs['variant_unit'] = nil
      @attrs['variant_unit_scale'] = nil
      @attrs['unit_value'] = nil

      return unless @attrs.key?('units') && @attrs['units'].present?

      @attrs['unscaled_units'] = @attrs['units']
    end

    def assign_weight_or_volume_attributes
      units = @attrs['units'].to_d
      unit_type = @attrs['unit_type'].to_s.downcase

      return unless valid_unit_type? unit_type

      @attrs['variant_unit'] = unit_scales[unit_type][:unit]
      @attrs['variant_unit_scale'] = unit_scales[unit_type][:scale]
      @attrs['unit_value'] = (units || 0) * @attrs['variant_unit_scale']
    end

    def assign_item_attributes
      units = @attrs['units'].to_f

      @attrs['variant_unit'] = 'items'
      @attrs['variant_unit_scale'] = nil
      @attrs['unit_value'] = units || 1
    end

    def units_and_unit_type_present?
      @attrs.key?('units') && @attrs.key?('unit_type') && @attrs['units'].present? &&
        @attrs['unit_type'].present?
    end

    def units_and_variant_unit_name_present?
      @attrs.key?('units') && @attrs.key?('variant_unit_name') && @attrs['units'].present? &&
        @attrs['variant_unit_name'].present?
    end

    def valid_unit_type?(unit_type)
      unit_scales.key? unit_type
    end
  end
end
