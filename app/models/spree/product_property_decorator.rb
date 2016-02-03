module Spree
  ProductProperty.class_eval do
    after_save :refresh_products_cache
    after_destroy :refresh_products_cache

    def refresh_products_cache
      product.refresh_products_cache
    end
  end
end
