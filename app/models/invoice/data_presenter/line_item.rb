# frozen_string_literal: false

class Invoice
  class DataPresenter
    class LineItem < Invoice::DataPresenter::Base
      attributes :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
                 :variant_id, :unit_price_price_and_unit, :unit_presentation, :enterprise_fee_tax
      attributes_with_presenter :variant
      array_attribute :tax_rates, class_name: 'TaxRate'
      invoice_generation_attributes :added_tax, :included_tax, :price_with_adjustments,
                                    :quantity, :variant_id

      delegate :name_to_display, :options_text, to: :variant

      def amount_with_adjustments_without_taxes
        (price_with_adjustments * quantity) - included_tax
      end

      def amount_with_adjustments_and_with_taxes
        fee_tax = enterprise_fee_tax || 0.00
        ( price_with_adjustments * quantity) + added_tax + fee_tax
      end

      def display_amount_with_adjustments_without_taxes
        Spree::Money.new(amount_with_adjustments_without_taxes, currency:)
      end

      def display_amount_with_adjustments_and_with_taxes
        Spree::Money.new(amount_with_adjustments_and_with_taxes, currency:)
      end

      def single_display_amount_with_adjustments
        Spree::Money.new(price_with_adjustments - (included_tax / quantity), currency:)
      end

      def display_line_items_taxes(display_zero: true)
        if included_tax.positive?
          Spree::Money.new( included_tax, currency:)
        elsif added_tax.positive?
          Spree::Money.new( added_tax, currency:)
        elsif display_zero
          Spree::Money.new(0.00, currency:)
        end
      end

      def display_line_item_tax_rates
        tax_rates.map { |tr| number_to_percentage(tr.amount * 100, precision: 1) }.join(", ")
      end
    end
  end
end
