module OpenFoodWeb
  class Calculator::Itemwise < Spree::Calculator

    def self.description
      "Itemwise Shipping"
    end

    def compute(object)
      # Given an order, sum the shipping on each individual item
      object.line_items.sum { |li| li.distribution_fee } || 0
    end
  end
end
