Spree::StockMovement.class_eval do
  after_save :refresh_products_cache

  private

  def refresh_products_cache
    return if stock_item.variant.blank?
    OpenFoodNetwork::ProductsCache.variant_changed stock_item.variant
  end
end
