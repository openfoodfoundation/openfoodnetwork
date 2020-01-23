module OpenFoodNetwork
  class OptionValueNamer
    def initialize(variant = nil)
      @variant = variant
    end

    def name(obj = nil)
      @variant = obj unless obj.nil?
      value, unit = option_value_value_unit
      separator = value_scaled? ? '' : ' '

      name_fields = []
      name_fields << "#{value}#{separator}#{unit}" if value.present? && unit.present?
      name_fields << @variant.unit_description if @variant.unit_description.present?
      name_fields.join ' '
    end

    def value
      value, = option_value_value_unit
      value
    end

    def unit
      _, unit = option_value_value_unit
      unit
    end

    private

    def value_scaled?
      @variant.product.variant_unit_scale.present?
    end

    def option_value_value_unit
      if @variant.unit_value.present?
        if %w(weight volume).include? @variant.product.variant_unit
          value, unit_name = option_value_value_unit_scaled

        else
          value = @variant.unit_value
          unit_name = pluralize(@variant.product.variant_unit_name, value)
        end

        value = value.to_i if value == value.to_i

      else
        value = unit_name = nil
      end

      [value, unit_name]
    end

    def option_value_value_unit_scaled
      unit_scale, unit_name = scale_for_unit_value

      value = @variant.unit_value / unit_scale

      [value, unit_name]
    end

    def scale_for_unit_value
      units = { 'weight' => { 1.0 => 'g', 1000.0 => 'kg', 1_000_000.0 => 'T' },
                'volume' => { 0.001 => 'mL', 1.0 => 'L',  1000.0 => 'kL' } }

      # Find the largest available unit where unit_value comes to >= 1 when expressed in it.
      # If there is none available where this is true, use the smallest available unit.
      unit = units[@variant.product.variant_unit].select { |scale, _unit_name|
        @variant.unit_value / scale >= 1
      }.to_a.last
      unit = units[@variant.product.variant_unit].first if unit.nil?

      unit
    end

    def pluralize(unit_name, count)
      I18nUnitNames.instance.pluralize(unit_name, count)
    end

    # Provides efficient access to unit name inflections.
    # The singleton property ensures that the init code is run once only.
    # The OptionValueNamer is instantiated in loops.
    class I18nUnitNames
      include Singleton

      def pluralize(unit_name, count)
        return unit_name if count.nil?

        @unit_keys ||= unit_key_lookup
        key = @unit_keys[unit_name.downcase]

        return unit_name unless key

        I18n.t(key, scope: "unit_names", count: count, default: unit_name)
      end

      private

      def unit_key_lookup
        lookup = {}
        I18n.t("unit_names").each do |key, translations|
          translations.values.each do |translation|
            lookup[translation.downcase] = key
          end
        end
        lookup
      end
    end
  end
end
