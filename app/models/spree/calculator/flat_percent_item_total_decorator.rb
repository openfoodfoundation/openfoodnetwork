Spree::Calculator::FlatPercentItemTotal.class_eval do
  # Spree's calculator sums all amounts, and then calculates a percentage on them.
  # In the cart, we display line item individual amounts rounded, so to have consistent
  # calculations we do the same internally. Here, we round adjustments at the individual
  # item level first, then multiply by the item quantity.


  def compute(object)
    line_items_for(object).sum do |li|
      unless li.price.present? && li.quantity.present?
        raise ArgumentError, "object must respond to #price and #quantity"
      end

      value = (li.price * BigDecimal(self.preferred_flat_percent.to_s) / 100.0).round(2)
      value * li.quantity
    end
  end
end
