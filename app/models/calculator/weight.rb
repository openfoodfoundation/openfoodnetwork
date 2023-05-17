# frozen_string_literal: true

module Calculator
  class Weight < Spree::Calculator
    preference :unit_from_list, :string, default: "kg"
    preference :per_unit, :decimal, default: 0.0

    def self.description
      I18n.t('spree.weight')
    end

    def set_preference(name, value)
      if name == :unit_from_list && !["kg", "lb"].include?(value)
        calculable.errors.add(:preferred_unit_from_list, I18n.t(:calculator_preferred_unit_error))
      else
        __send__ self.class.preference_setter_method(name), value
      end
    end

    def compute(object)
      line_items = line_items_for object
      (total_weight(line_items) * preferred_per_unit).round(2)
    end

    def preferred_unit_from_list_values
      ["kg", "lb"]
    end

    private

    def total_weight(line_items)
      line_items.to_a.sum do |line_item|
        line_item_weight(line_item)
      end
    end

    def line_item_weight(line_item)
      if final_weight_volume_present?(line_item)
        weight_per_final_weight_volume(line_item)
      else
        weight_per_variant(line_item) * line_item.quantity
      end
    end

    def weight_per_variant(line_item)
      if variant_unit(line_item) == 'weight'
        # Convert unit_value to the preferred unit
        convert_weight(line_item.variant&.unit_value)
      else
        line_item.variant&.weight || 0
      end
    end

    def weight_per_final_weight_volume(line_item)
      if variant_unit(line_item) == 'weight'
        # Convert final_weight_volume to the preferred unit
        convert_weight(line_item.final_weight_volume)
      else
        weight_per_variant(line_item) * quantity_implied_in_final_weight_volume(line_item)
      end
    end

    #  Example: 2 (line_item.quantity) wine glasses of 125mL (line_item.variant.unit_value)
    #    Customer ends up getting 350mL (line_item.final_weight_volume) of wine
    #      that represent 2.8 (quantity_implied_in_final_weight_volume) glasses of wine
    def quantity_implied_in_final_weight_volume(line_item)
      return line_item.quantity if line_item.variant.unit_value.to_f.zero?

      (1.0 * line_item.final_weight_volume / line_item.variant.unit_value).round(3)
    end

    def final_weight_volume_present?(line_item)
      line_item.respond_to?(:final_weight_volume) && line_item.final_weight_volume.present?
    end

    def variant_unit(line_item)
      line_item.variant.product&.variant_unit
    end

    def convert_weight(value)
      return 0 unless value && ["kg", "lb"].include?(preferences[:unit_from_list])

      if preferences[:unit_from_list] == "kg"
        value / 1000
      elsif preferences[:unit_from_list] == "lb"
        value / 453.6
      end
    end
  end
end
