module Spree
  Calculator::FlatPercentItemTotal.class_eval do
    def compute(object)
      item_total = line_items_for(object).map(&:amount).sum
      value = item_total * BigDecimal(self.preferred_flat_percent.to_s) / 100.0
      (value * 100).round.to_f / 100
    end
  end
end
