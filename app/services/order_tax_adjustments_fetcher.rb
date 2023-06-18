# frozen_string_literal: true

# Collects Tax Adjustments related to an order, and returns a hash with a total for each rate.

class OrderTaxAdjustmentsFetcher
  def initialize(order)
    @order = order
  end

  def totals(tax_adjustments = order.all_adjustments.tax)
    tax_adjustments.each_with_object({}) do |adjustment, hash|
      tax_rate = adjustment.originator
      hash[tax_rate] = hash[tax_rate].to_f + adjustment.amount
    end
  end

  private

  attr_reader :order
end
