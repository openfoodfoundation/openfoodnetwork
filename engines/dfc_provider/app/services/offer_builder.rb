# frozen_string_literal: true

class OfferBuilder < DfcBuilder
  def self.build(variant)
    id = urls.enterprise_offer_url(
      enterprise_id: variant.supplier_id,
      id: variant.id,
    )

    DataFoodConsortium::Connector::Offer.new(
      id,
      price: variant.price.to_f,
      stockLimitation: stock_limitation(variant),
    )
  end

  def self.apply(offer, variant)
    return if offer.nil?

    CatalogItemBuilder.apply_stock(offer, variant)

    return if offer.price.nil?

    variant.price = price(offer)
  end

  def self.price(offer)
    # We assume same currency here:
    if offer.price.respond_to?(:value)
      offer.price.value
    else
      offer.price
    end
  end
end
