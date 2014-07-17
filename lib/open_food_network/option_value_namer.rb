module OpenFoodNetwork
  class OptionValueNamer < Struct.new(:variant)
    def name
      value, unit = self.option_value_value_unit
      separator = self.value_scaled? ? '' : ' '

      name_fields = []
      name_fields << "#{value}#{separator}#{unit}" if value.present? && unit.present?
      name_fields << variant.unit_description   if variant.unit_description.present?
      name_fields.join ' '
    end

    def value_scaled?
      variant.product.variant_unit_scale.present?
    end

    def option_value_value_unit
      if variant.unit_value.present?
        if %w(weight volume).include? variant.product.variant_unit
          value, unit_name = self.option_value_value_unit_scaled

        else
          value = variant.unit_value
          unit_name = variant.product.variant_unit_name
          unit_name = unit_name.pluralize if value > 1
        end

        value = value.to_i if value == value.to_i

      else
        value = unit_name = nil
      end

      [value, unit_name]
    end

    def option_value_value_unit_scaled
      unit_scale, unit_name = self.scale_for_unit_value

      value = variant.unit_value / unit_scale

      [value, unit_name]
    end

    def scale_for_unit_value
      units = {'weight' => {1.0 => 'g', 1000.0 => 'kg', 1000000.0 => 'T'},
               'volume' => {0.001 => 'mL', 1.0 => 'L',  1000.0 => 'kL'}}

      # Find the largest available unit where unit_value comes to >= 1 when expressed in it.
      # If there is none available where this is true, use the smallest available unit.
      unit = units[variant.product.variant_unit].select { |scale, unit_name|
        variant.unit_value / scale >= 1
      }.to_a.last
      unit = units[variant.product.variant_unit].first if unit.nil?

      unit
    end
  end
end
