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
      tax_total = adjustments.tax.reload.map(&:update!).compact.sum
      adjustment_total = adjustments.map(&:amount).compact.sum

      item.update_columns(tax_total: tax_total, adjustment_total: adjustment_total)
    end
  end
end
