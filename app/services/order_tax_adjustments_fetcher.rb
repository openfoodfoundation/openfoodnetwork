# This class will be used to get Tax Adjustments related to an order,
# and proceed basic calcultation over them.

class OrderTaxAdjustmentsFetcher
  def initialize(order)
    @order = order
  end

  def totals
    all.each_with_object({}) do |adjustment, hash|
      tax_rates = TaxRateFinder.tax_rates_of(adjustment)
      tax_rates_hash = Hash[tax_rates.collect do |tax_rate|
        tax_amount = tax_rates.one? ? adjustment.included_tax : tax_rate.compute_tax(adjustment.amount)
        [tax_rate, tax_amount]
      end]
      hash.update(tax_rates_hash) { |_tax_rate, amount1, amount2| amount1 + amount2 }
    end
  end

  private

  attr_reader :order

  def all
    order.adjustments.with_tax +
      order.line_items.includes(:adjustments).map { |li| li.adjustments.with_tax }.flatten
  end
end