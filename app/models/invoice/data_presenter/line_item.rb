# frozen_string_literal: false

class Invoice
  class DataPresenter
    class LineItem < Invoice::DataPresenter::Base
      attributes :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
                 :variant_id
      attributes_with_presenter :variant
      invoice_generation_attributes :added_tax, :included_tax, :price_with_adjustments,
                                    :quantity, :variant_id

      delegate :name_to_display, :options_text, to: :variant

      def display_amount_with_adjustments
        Spree::Money.new((price_with_adjustments * quantity), currency: currency)
      end

      def single_display_amount_with_adjustments
        Spree::Money.new(price_with_adjustments, currency: currency)
      end

      def display_line_items_taxes(display_zero: true)
        if included_tax.positive?
          Spree::Money.new( included_tax, currency: currency)
        elsif added_tax.positive?
          Spree::Money.new( added_tax, currency: currency)
        elsif display_zero
          Spree::Money.new(0.00, currency: currency)
        end
      end
    end
  end
end
