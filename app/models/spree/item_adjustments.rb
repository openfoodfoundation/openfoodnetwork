# frozen_string_literal: true

# We should probably adapt OFN fees to go through this class. It was origianlly designed for
# applying adjustments to different items and included a lot of promotions-related code, which function
# a bit like our fees...

module Spree
  # Manage (recalculate) item (LineItem or Shipment) adjustments
  class ItemAdjustments
    attr_reader :item

    delegate :adjustments, :order, to: :item

    def initialize(item)
      @item = item

      # This line is added in a later PR in Spree 2.2 (stable):
      # @item.reload if @item.persisted?
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

      included_tax_total = adjustments.tax.included.reload.map(&:update!).compact.sum
      additional_tax_total = adjustments.tax.additional.reload.map(&:update!).compact.sum
      adjustment_total = adjustments.reload.map(&:amount).compact.sum

      item.update_columns(
        included_tax_total: included_tax_total,
        additional_tax_total: additional_tax_total,
        adjustment_total: adjustment_total - included_tax_total,
        updated_at: Time.now
      )
    end
  end
end
