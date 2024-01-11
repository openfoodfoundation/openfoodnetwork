# frozen_string_literal: true

class OfferBuilder < DfcBuilder
  def self.apply(offer, variant)
    variant.on_hand = offer.stockLimitation
    variant.price = offer.price
  end
end
