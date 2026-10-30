# frozen_string_literal: false

class Invoice
  class DataPresenter
    class LineItem < Invoice::DataPresenter::Base
      attributes :id, :added_tax, :currency, :included_tax, :price_with_adjustments, :quantity,
                 :variant_id, :unit_price, :unit_presentation,
                 :enterprise_fee_additional_tax, :enterprise_fee_included_tax,
                 :product_name, :variant_display_name
      attributes_with_presenter :variant, :supplier
      invoice_generation_attributes :added_tax, :included_tax, :price_with_adjustments,
                                    :quantity, :variant_id

      delegate :options_text, to: :variant

      def full_product_name
        product_name.nil? ? variant.product.name : product_name
      end

      def name_to_display
        return variant_display_name unless variant_display_name.nil?
        return variant.display_name if variant.display_name.present?
        return product_name unless product_name.nil?

        variant.product.name
      end

      def amount_with_adjustments_without_taxes
        fee_tax = enterprise_fee_included_tax || 0.0
        (price_with_adjustments * quantity) - included_tax - fee_tax
      end

      def amount_with_adjustments_and_with_taxes
        fee_tax = enterprise_fee_additional_tax || 0.0
        ( price_with_adjustments * quantity) + added_tax + fee_tax
      end

      def display_amount_with_adjustments_without_taxes
        Spree::Money.new(amount_with_adjustments_without_taxes, currency:)
      end

      def display_amount_with_adjustments_and_with_taxes
        Spree::Money.new(amount_with_adjustments_and_with_taxes, currency:)
      end

      def single_display_amount_with_adjustments
        fee_tax = enterprise_fee_included_tax || 0.0
        Spree::Money.new(price_with_adjustments - ((included_tax + fee_tax) / quantity), currency:)
      end
    end
  end
end
