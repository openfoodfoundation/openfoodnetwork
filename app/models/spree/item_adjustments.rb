# frozen_string_literal: true

# We should probably adapt OFN fees to go through this class. It was origianlly designed for
# applying adjustments to different items and included a lot of promotions-related code, which function
# a bit like our fees...

module Spree
  # Manage (recalculate) item (LineItem or Shipment) adjustments
  class ItemAdjustments
    include ActiveSupport::Callbacks
    define_callbacks :tax_adjustments

    attr_reader :item

    delegate :adjustments, :order, to: :item

    def initialize(item)
      @item = item
      @item.reload if @item.persisted?
    end

    def update
      update_adjustments if item.persisted?
      item
    end

    def update_adjustments
      # OFN fees should be applied here. Fees should be added before the tax calculations are done.
      # See the promotions-related code here in 2-2-stable for reference, it's doing something similar.

      # Tax adjustments come in not one but *two* exciting flavours: Included & additional
      # Included tax adjustments are those which are included in the price.
      # These ones should not effect the eventual total price.
      # Additional tax adjustments are the opposite; effecting the final total.

      adjustment_total = adjustments.reload.map(&:amount).compact.sum

      included_tax_total = 0
      additional_tax_total = 0
      run_callbacks :tax_adjustments do
        tax = (item.respond_to?(:all_adjustments) ? item.all_adjustments : item.adjustments).tax
        included_tax_total = tax.included.reload.map(&:update!).compact.sum
        additional_tax_total = tax.additional.reload.map(&:update!).compact.sum
      end

      item.update_columns(
        included_tax_total: included_tax_total,
        additional_tax_total: additional_tax_total,
        adjustment_total: adjustment_total - included_tax_total,
        updated_at: Time.now
      )
    end
  end
end
