# frozen_string_literal: true

module TaxHelper
  def display_taxes(taxable, display_zero: true)
    if !taxable.included_tax_total.zero?
      amount = Spree::Money.new(taxable.included_tax_total, currency: taxable.currency)
      I18n.t(:tax_amount_included, amount: amount)
    elsif !taxable.additional_tax_total.zero?
      Spree::Money.new(taxable.additional_tax_total, currency: taxable.currency)
    elsif display_zero
      Spree::Money.new(0.00, currency: taxable.currency)
    end
  end

  def display_line_items_taxes(line_item, display_zero: true)
    if line_item.included_tax.positive?
      Spree::Money.new(line_item.included_tax, currency: line_item.currency)
    elsif line_item.added_tax.positive?
      Spree::Money.new(line_item.added_tax, currency: line_item.currency)
    elsif display_zero
      Spree::Money.new(0.00, currency: line_item.currency)
    end
  end

  def display_total_with_tax(taxable)
    total = taxable.amount + taxable.additional_tax_total
    Spree::Money.new(total, currency: taxable.currency)
  end
end
