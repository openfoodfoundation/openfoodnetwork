# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Adjustment < Invoice::DataPresenter::Base
      attributes :additional_tax_total, :adjustable_type, :amount, :currency, :included_tax_total,
                 :label
      array_attribute :tax_rates, class_name: 'TaxRate'
      attributes_with_presenter :originator, class_name: 'AdjustmentOriginator'
      attributes_with_presenter :adjustable
      invoice_generation_attributes :additional_tax_total, :adjustable_type, :amount,
                                    :included_tax_total
      invoice_update_attributes :label

      def display_amount_with_taxes
        Spree::Money.new(amount + additional_tax_total, currency:)
      end

      def display_amount_without_taxes
        Spree::Money.new(amount - included_tax_total, currency:)
      end

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

      def display_adjustment_tax_rates
        tax_rates.map { |tr| number_to_percentage(tr.amount * 100, precision: 1) }.join(", ")
      end
    end
  end
end
