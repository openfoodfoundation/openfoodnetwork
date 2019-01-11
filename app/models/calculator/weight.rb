module Calculator
  class Weight < Spree::Calculator
    preference :per_kg, :decimal, default: 0.0
    attr_accessible :preferred_per_kg

    def self.description
      I18n.t('spree.weight')
    end

    def compute(object)
      line_items = line_items_for object
      total_weight = line_items.sum { |li| ((li.variant.andand.weight || 0) * li.quantity) }
      total_weight * preferred_per_kg
    end
  end
end
