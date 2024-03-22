# frozen_string_literal: true

class OfferBuilder < DfcBuilder
  def self.build(variant)
    id = urls.enterprise_offer_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )

    DataFoodConsortium::Connector::Offer.new(
      id,
      price: variant.price.to_f,
      stockLimitation: stock_limitation(variant),
    )
  end

  def self.apply(offer, variant)
    variant.on_hand = offer.stockLimitation
    variant.price = offer.price
  end
end
