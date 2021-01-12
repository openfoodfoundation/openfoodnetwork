# frozen_string_literal: true

# This class will be used to get Tax Adjustments related to an order,
# and proceed basic calcultation over them.

# This class is not good and needs to be revised/deleted. It's currently used in 2 places:
# - Displaying a few tax adjustment values on te checkout page
# - Displaying tax adjustment data in the SalesTaxReport
#
# It relies on TaxRate#compute_tax, which also needs to be revised/deleted. The method only
# works correctly for tax regimes with *inclusive* tax and does not work for others. The TaxRate
# class now has greatly improved methods for applying either inclusive or additional tax rates
# correctly, and we need to use them directly and remove our hacks.

class OrderTaxAdjustmentsFetcher
  def initialize(order)
    @order = order
  end

  def totals
    tax_adjustments.each_with_object({}) do |adjustment, hash|
      tax_rates_hash = tax_rates_hash(adjustment)
      hash.update(tax_rates_hash) { |_tax_rate, amount1, amount2| amount1 + amount2 }
    end
  end

  private

  attr_reader :order

  def tax_adjustments
    order.all_adjustments.tax.to_a +         # Proper tax adjustments
      order.adjustments.admin.with_tax.to_a  # Arbitrary adjustments added via admin UI
  end

  def tax_rates_hash(adjustment)
    tax_rates = TaxRateFinder.tax_rates_of(adjustment)

    Hash[tax_rates.collect do |tax_rate|
      tax_amount = if admin_adjustment? adjustment
                     adjustment.included_tax
                   else
                     adjustment.amount
                   end
      [tax_rate, tax_amount]
    end]
  end

  def admin_adjustment?(adjustment)
    adjustment.source_id.nil?
  end
end
