module Spree
  Property.class_eval do
    after_save :refresh_products_cache

    # When a Property is destroyed, dependent-destroy will destroy all ProductProperties,
    # which will take care of refreshing the products cache


    private

    def refresh_products_cache
      product_properties(:reload).each &:refresh_products_cache
    end
  end
end
