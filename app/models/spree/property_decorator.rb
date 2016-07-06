module Spree
  Property.class_eval do
    scope :applied_by, ->(enterprise) {
      select('DISTINCT spree_properties.*').
        joins(:product_properties).
        where('spree_product_properties.product_id IN (?)', enterprise.supplied_product_ids)
    }

    after_save :refresh_products_cache

    # When a Property is destroyed, dependent-destroy will destroy all ProductProperties,
    # which will take care of refreshing the products cache


    private

    def refresh_products_cache
      product_properties(:reload).each &:refresh_products_cache
    end
  end
end
