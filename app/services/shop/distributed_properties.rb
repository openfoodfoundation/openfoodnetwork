# frozen_string_literal: true

# Properties of products distributed by a shop in any order cycle, including the properties of
# their producers when the products inherit them.
module Shop
  class DistributedProperties
    def initialize(distributor)
      @distributor = distributor
    end

    def relation
      Spree::Property.where(id: product_property_ids)
        .or(Spree::Property.where(id: producer_property_ids))
    end

    private

    def variants
      Spree::Variant.joins(:exchanges)
        .merge(Exchange.outgoing).merge(Exchange.to_enterprise(@distributor))
    end

    def product_property_ids
      Spree::ProductProperty.where(product_id: variants.select(:product_id)).select(:property_id)
    end

    def producer_property_ids
      producer_ids = variants.joins(:product)
        .where(spree_products: { inherits_properties: true }).select(:enterprise_id)
      ProducerProperty.where(producer_id: producer_ids).select(:property_id)
    end
  end
end
