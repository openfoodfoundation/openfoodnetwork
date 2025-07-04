# frozen_string_literal: true

class OfferBuilder < DfcBuilder
  def self.build(variant)
    id = urls.enterprise_offer_url(
      enterprise_id: variant.supplier_id,
      id: variant.id,
    )

    price = DataFoodConsortium::Connector::Price.new(
      value: variant.price.to_f,
      unit: price_measure(variant)&.semanticId,
    )
    DataFoodConsortium::Connector::Offer.new(
      id, price:, stockLimitation: stock_limitation(variant),
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

  # The DFC measures define only five currencies at the moment.
  # And they are not standardised enough to align with our ISO 4217
  # currency codes. So I propose to just use those currency codes instead.
  # https://github.com/datafoodconsortium/taxonomies/issues/48
  def self.price_measure(variant)
    measures = DfcLoader.vocabulary("measures")

    case variant.currency
    when "AUD"
      measures.AUSTRALIANDOLLAR
    when "CAD"
      measures.CANADIANDOLLAR
    when "EUR"
      measures.EURO
    when "GBP"
      measures.POUNDSTERLING
    when "USD"
      measures.USDOLLAR
    end
  end
end
