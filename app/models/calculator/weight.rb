require 'spree/localized_number'

module Calculator
  class Weight < Spree::Calculator
    extend Spree::LocalizedNumber
    preference :per_kg, :decimal, default: 0.0
    localize_number :preferred_per_kg

    def self.description
      I18n.t('spree.weight')
    end

    def compute(object)
      line_items = line_items_for object
      (total_weight(line_items) * preferred_per_kg).round(2)
    end

    private

    def total_weight(line_items)
      line_items.sum do |line_item|
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
        # The calculator price is per_kg so we need to convert unit_value to kg
        convert_g_to_kg(line_item.variant.andand.unit_value)
      else
        line_item.variant.andand.weight || 0
      end
    end

    def weight_per_final_weight_volume(line_item)
      if variant_unit(line_item) == 'weight'
        # The calculator price is per_kg so we need to convert final_weight_volume to kg
        convert_g_to_kg(line_item.final_weight_volume)
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
      line_item.variant.product.andand.variant_unit
    end

    def convert_g_to_kg(value)
      return 0 unless value

      value / 1000
    end
  end
end
