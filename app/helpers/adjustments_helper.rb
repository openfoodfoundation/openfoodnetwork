# frozen_string_literal: true

module AdjustmentsHelper
  def display_adjustment_taxes(adjustment)
    if adjustment.included_tax_total > 0
      amount = Spree::Money.new(adjustment.included_tax_total, currency: adjustment.currency)
      I18n.t(:tax_amount_included, amount: amount)
    elsif adjustment.additional_tax_total > 0
      Spree::Money.new(adjustment.additional_tax_total, currency: adjustment.currency)
    else
      Spree::Money.new(0.00, currency: adjustment.currency)
    end
  end
end
