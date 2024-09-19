# frozen_string_literal: true

class CatalogItemBuilder < DfcBuilder
  def self.apply_stock(item, variant)
    limit = item&.stockLimitation

    return if limit.blank?

    # Negative stock means "on demand".
    # And we are only interested in that for now.
    return unless limit.to_i.negative?

    if variant.stock_items.empty?
      variant.stock_items << Spree::StockItem.new(
        stock_location: DefaultStockLocation.find_or_create,
        variant:,
      )
    end

    variant.stock_items[0].backorderable = true
  end
end
