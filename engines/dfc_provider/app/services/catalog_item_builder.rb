# frozen_string_literal: true

class CatalogItemBuilder < DfcBuilder
  def self.apply_stock(item, variant)
    limit = item&.stockLimitation

    return if limit.blank?

    if variant.stock_items.empty?
      variant.stock_items << Spree::StockItem.new(
        variant:,
      )
    end

    if limit.to_i.negative?
      variant.stock_items[0].backorderable = true
    else
      variant.stock_items[0].count_on_hand = limit
    end
  end
end
