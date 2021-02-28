# frozen_string_literal: true

# This class will be used to get Tax Adjustments related to an order,
# and proceed basic calcultation over them.

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
      .where(order_adjustments.or(line_item_adjustments).or(shipment_adjustments))
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

  def shipment_adjustments
    table[:order_id].eq(order.id)
      .and(table[:adjustable_type].eq('Spree::Shipment'))
  end

  def table
    @table ||= Spree::Adjustment.arel_table
  end

  def tax_rates_hash(adjustment)
    tax_rates = TaxRateFinder.tax_rates_of(adjustment)

    Hash[tax_rates.collect do |tax_rate|
      tax_amount = if tax_rates.one?
                     adjustment_tax_amount(adjustment)
                   else
                     tax_rate.compute_tax(adjustment.amount)
                   end
      [tax_rate, tax_amount]
    end]
  end

  def adjustment_tax_amount(adjustment)
    if no_tax_adjustments?(adjustment)
      adjustment.included_tax
    else
      adjustment.amount
    end
  end

  def no_tax_adjustments?(adjustment)
    # Enterprise Fees, Admin Adjustments, and Shipping Fees currently do not have tax adjustments.
    # The tax amount is stored in the included_tax attribute.
    adjustment.originator_type == "EnterpriseFee" ||
      adjustment.originator_type == "Spree::ShippingMethod" ||
      (adjustment.source_type.nil? && adjustment.originator_type.nil?)
  end
end
