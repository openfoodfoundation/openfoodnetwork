# frozen_string_literal: true

class CatalogItemBuilder < DfcBuilder
  def self.catalog_item(variant)
    id = urls.enterprise_catalog_item_url(
      enterprise_id: variant.supplier_id,
      id: variant.id,
    )
    supplier_url = urls.enterprise_url(variant.supplier_id)
    product = SuppliedProductBuilder.supplied_product(variant)

    DfcProvider::CatalogItem.new(
      id, product:,
          sku: variant.sku,
          stockLimitation: stock_limitation(variant),
          offers: [OfferBuilder.build(variant)],
          managedBy: supplier_url,
    )
  end

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
      variant.stock_items[0].backorderable = false
      variant.stock_items[0].count_on_hand = limit
    end
  end
end
