# frozen_string_literal: true

# Finds wholesale offers for retail products.
class FdcOfferBroker
  # TODO: Find a better way to provide this data.
  Solution = Struct.new(:product, :factor, :offer)
  RetailSolution = Struct.new(:retail_product_id, :factor)

  def initialize(catalog)
    @catalog = catalog
  end

  def best_offer(product_id)
    consumption_flow = catalog_item("#{product_id}/AsPlannedConsumptionFlow")
    production_flow = catalog_item("#{product_id}/AsPlannedProductionFlow")

    contained_quantity = consumption_flow.quantity.value.to_i
    wholesale_product_id = production_flow.product
    wholesale_product = catalog_item(wholesale_product_id)

    offer = offer_of(wholesale_product)

    Solution.new(wholesale_product, contained_quantity, offer)
  end

  def wholesale_to_retail(wholesale_product_id)
    production_flow = flow_producing(wholesale_product_id)
    consumption_flow = catalog_item(
      production_flow.semanticId.sub("AsPlannedProductionFlow", "AsPlannedConsumptionFlow")
    )
    retail_product_id = consumption_flow.product

    contained_quantity = consumption_flow.quantity.value.to_i

    RetailSolution.new(retail_product_id, contained_quantity)
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

  def flow_producing(wholesale_product_id)
    @production_flows_by_product_id ||= production_flows.index_by(&:product)
    @production_flows_by_product_id[wholesale_product_id]
  end

  def production_flows
    @production_flows ||= @catalog.select do |i|
      i.semanticType == "dfc-b:AsPlannedProductionFlow"
    end
  end
end
