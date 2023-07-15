# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Adjustable < Invoice::DataPresenter::Base
      attributes :id, :type, :currency, :included_tax_total, :additional_tax_total, :amount

      def display_taxes(display_zero: false)
        if included_tax_total.positive?
          amount = Spree::Money.new(included_tax_total, currency:)
          I18n.t(:tax_amount_included, amount:)
        elsif additional_tax_total.positive?
          Spree::Money.new(additional_tax_total, currency:)
        elsif display_zero
          Spree::Money.new(0.00, currency:)
        end
      end
    end
  end
end
