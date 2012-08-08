module OpenFoodWeb
  class Calculator::Weight < Spree::Calculator
    preference :per_kg, :decimal, :default => 0.0
    attr_accessible :preferred_per_kg

    def self.description
      "Weight (per kg)"
    end

    def compute(object)
      total_weight = object.line_items.inject(0) { |sum, li| sum + ((li.variant.andand.weight || 0) * li.quantity) }
      total_weight * self.preferred_per_kg
    end
  end
end
