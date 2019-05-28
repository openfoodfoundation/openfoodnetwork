module Spree
  ProductProperty.class_eval do
    belongs_to :product, class_name: "Spree::Product", touch: true

    after_save :refresh_products_cache
    after_destroy :refresh_products_cache

    delegate :refresh_products_cache, to: :product
  end
end
