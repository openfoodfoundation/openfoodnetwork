# frozen_string_literal: true

# Collects Tax Adjustments related to an order, and returns a hash with a total for each rate.

class OrderTaxAdjustmentsFetcher
  def initialize(order)
    @order = order
  end

  def totals
    order.all_adjustments.tax.each_with_object({}) do |adjustment, hash|
      tax_rate = adjustment.originator
      tax_amounts = { tax_rate => adjustment.amount }
      hash.update(tax_amounts) { |_tax_rate, amount1, amount2| amount1 + amount2 }
    end
  end

  private

  attr_reader :order
end
