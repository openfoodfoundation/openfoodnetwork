# frozen_string_literal: true

require "open_food_network/i18n_inflections"

module VariantUnits
  class OptionValueNamer
    # nameable can be either a Spree::LineItem or a Spree::Variant
    def initialize(nameable = nil)
      @nameable = nameable
    end

    def name
      value, unit = option_value_value_unit
      separator = value_scaled? ? '' : ' '

      name_fields = []
      name_fields << "#{value}#{separator}#{unit}" if value.present? && unit.present?
      name_fields << @nameable.unit_description if @nameable.unit_description.present?
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
      @nameable.product.variant_unit_scale.present?
    end

    def option_value_value_unit
      if @nameable.unit_value.present? && @nameable.product&.persisted?
        if %w(weight volume).include? @nameable.product.variant_unit
          value, unit_name = option_value_value_unit_scaled
        else
          value = @nameable.unit_value
          unit_name = pluralize(@nameable.product.variant_unit_name, value)
        end

        value = value.to_i if value == value.to_i

      else
        value = unit_name = nil
      end

      [value, unit_name]
    end

    def option_value_value_unit_scaled
      unit_scale, unit_name = scale_for_unit_value

      value = (@nameable.unit_value / unit_scale).to_d.truncate(2)

      [value, unit_name]
    end

    def scale_for_unit_value
      WeightsAndMeasures.new(@nameable).scale_for_unit_value
    end

    def pluralize(unit_name, count)
      OpenFoodNetwork::I18nInflections.pluralize(unit_name, count)
    end
  end
end
