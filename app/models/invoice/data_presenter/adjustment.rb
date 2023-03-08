class Invoice::DataPresenter::Adjustment < Invoice::DataPresenter::Base
  attributes :adjustable_type, :label, :included_tax_total, :additional_tax_total, :amount,
             :currency

  def display_amount
    Spree::Money.new(amount, currency: currency)
  end

  def display_taxes(display_zero: false)
    if included_tax_total.positive?
      amount = Spree::Money.new(included_tax_total, currency: currency)
      I18n.t(:tax_amount_included, amount: amount)
    elsif additional_tax_total.positive?
      Spree::Money.new(additional_tax_total, currency: currency)
    elsif display_zero
      Spree::Money.new(0.00, currency: currency)
    end
  end
end
