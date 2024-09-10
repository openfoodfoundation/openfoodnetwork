# frozen_string_literal: true

# Finds wholesale offers for retail products.
class FdcOfferBroker
  Solution = Struct.new(:product, :factor, :offer)

  def initialize(catalog)
    @catalog = catalog
  end

  def best_offer(product_id)
    consumption_flow = catalog_item("#{product_id}/AsPlannedConsumptionFlow")
    production_flow = catalog_item("#{product_id}/AsPlannedProductionFlow")

    contained_quantity = consumption_flow.quantity.value.to_i
    wholesale_product_id = production_flow.product
    wholesale_product = catalog_item(wholesale_product_id )

    offer = offer_of(wholesale_product)

    Solution.new(wholesale_product, contained_quantity, offer)
  end

  def offer_of(product)
    product&.catalogItems&.first&.offers&.first&.tap do |offer|
      # Unfortunately, the imported catalog doesn't provide the reverse link:
      offer.offeredItem = product
    end
  end

  def catalog_item(id)
    @catalog_by_id ||= @catalog.index_by(&:semanticId)
    @catalog_by_id[id]
  end
end
