module OpenFoodWeb
  class Calculator::Itemwise < Spree::Calculator

    def self.description
      "Itemwise Shipping"
    end

    def compute(object)
      # Given an order, sum the shipping on each individual item
      object.line_items.map { |li| li.itemwise_shipping_cost }.inject(:+) || 0
    end
  end
end
