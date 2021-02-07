# frozen_string_literal: true

module Spree
  # Manage (recalculate) item (LineItem or Shipment) adjustments
  class ItemAdjustments
    attr_reader :item

    delegate :adjustments, :order, to: :item

    def initialize(item)
      @item = item
    end

    def update
      update_adjustments if item.persisted?
      item
    end

    def update_adjustments
      adjustment_total = adjustments.map(&:update!).compact.sum

      item.update_columns(
        adjustment_total: adjustment_total,
        updated_at: Time.zone.now
      )
    end
  end
end
