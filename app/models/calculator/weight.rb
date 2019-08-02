require 'spree/localized_number'

module Calculator
  class Weight < Spree::Calculator
    extend Spree::LocalizedNumber
    preference :per_kg, :decimal, default: 0.0
    attr_accessible :preferred_per_kg
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
      if line_item.final_weight_volume.present?
        weight_per_final_weight_volume(line_item)
      else
        weight_per_variant(line_item) * line_item.quantity
      end
    end

    def weight_per_variant(line_item)
      line_item.variant.andand.weight || 0
    end

    def weight_per_final_weight_volume(line_item)
      if line_item.variant.product.andand.variant_unit == 'weight'
        # Divided by 1000 because grams is the base weight unit and the calculator price is per_kg
        line_item.final_weight_volume / 1000.0
      else
        weight_per_variant(line_item) * quantity_implied_in_final_weight_volume(line_item)
      end
    end

    def quantity_implied_in_final_weight_volume(line_item)
      (1.0 * line_item.final_weight_volume / line_item.variant.unit_value).round(3)
    end
  end
end
