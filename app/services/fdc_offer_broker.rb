# frozen_string_literal: true

# Finds wholesale offers for retail products.
class FdcOfferBroker
  def initialize(catalog)
    @catalog = catalog
  end

  def best_offer(product_id)
    product = @catalog.find { |item| item.semanticId == product_id }
    offer_of(product)
  end

  def offer_of(product)
    product&.catalogItems&.first&.offers&.first&.tap do |offer|
      # Unfortunately, the imported catalog doesn't provide the reverse link:
      offer.offeredItem = product
    end
  end
end
