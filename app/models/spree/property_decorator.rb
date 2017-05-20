module Spree
  Property.class_eval do
    has_many :producer_properties

    scope :applied_by, ->(enterprise) {
      select('DISTINCT spree_properties.*').
        joins(:product_properties).
        where('spree_product_properties.product_id IN (?)', enterprise.supplied_product_ids)
    }

    scope :ever_sold_by, ->(shop) {
      joins(products: {variants: {exchanges: :order_cycle}}).
        merge(Exchange.outgoing).
        merge(Exchange.to_enterprise(shop)).
        select('DISTINCT spree_properties.*')
    }

    scope :currently_sold_by, ->(shop) {
      ever_sold_by(shop).
        merge(OrderCycle.active)
    }


    after_save :refresh_products_cache

    # When a Property is destroyed, dependent-destroy will destroy all ProductProperties,
    # which will take care of refreshing the products cache


    private

    def refresh_products_cache
      product_properties(:reload).each(&:refresh_products_cache)
    end
  end
end
