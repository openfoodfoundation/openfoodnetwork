module Spree
  Price.class_eval do
    after_save :refresh_products_cache
    after_destroy :refresh_products_cache


    private

    def refresh_products_cache
      variant.refresh_products_cache
    end
  end
end
