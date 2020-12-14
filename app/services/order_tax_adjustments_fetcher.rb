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
    all.each_with_object({}) do |adjustment, hash|
      tax_rates_hash = tax_rates_hash(adjustment)
      hash.update(tax_rates_hash) { |_tax_rate, amount1, amount2| amount1 + amount2 }
    end
  end

  private

  attr_reader :order

  def all
    Spree::Adjustment
      .with_tax
      .where(order_adjustments.or(line_item_adjustments))
      .order('created_at ASC')
  end

  def order_adjustments
    table[:adjustable_id].eq(order.id)
      .and(table[:adjustable_type].eq('Spree::Order'))
  end

  def line_item_adjustments
    table[:adjustable_id].eq_any(order.line_item_ids)
      .and(table[:adjustable_type].eq('Spree::LineItem'))
  end

  def table
    @table ||= Spree::Adjustment.arel_table
  end

  def tax_rates_hash(adjustment)
    tax_rates = TaxRateFinder.tax_rates_of(adjustment)

    Hash[tax_rates.collect do |tax_rate|
      tax_amount = if tax_rates.one?
                     adjustment.included_tax
                   else
                     tax_rate.compute_tax(adjustment.amount)
                   end
      [tax_rate, tax_amount]
    end]
  end
end
