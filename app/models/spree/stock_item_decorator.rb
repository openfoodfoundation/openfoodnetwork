Spree::StockItem.class_eval do
  after_save :refresh_products_cache

  def refresh_products_cache
    OpenFoodNetwork::ProductsCache.variant_changed(variant)
  end
end
