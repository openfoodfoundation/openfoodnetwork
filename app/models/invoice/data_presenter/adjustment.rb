# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Adjustment < Invoice::DataPresenter::Base
      attributes :additional_tax_total, :adjustable_type, :amount, :currency, :included_tax_total,
                 :label, :originator_type
      invoice_generation_attributes :additional_tax_total, :adjustable_type, :amount,
                                    :included_tax_total
      invoice_update_attributes :label

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
  end
end
