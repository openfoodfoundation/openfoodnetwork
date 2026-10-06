# frozen_string_literal: true

class DfcBuilder
  # Unlimited stock is expressed as a negative number.
  #
  # An empty value doesn't mean anything in the semantic web: the absence of
  # data contains no information. So we can't leave the limitation out to say
  # that stock is unlimited. The negative number is what the DFC came up with
  # and it's used by the Shopify integration (FDC).
  def self.stock_limitation(variant)
    variant.on_demand ? -1 : variant.total_on_hand
  end

  def self.urls
    DfcProvider::Engine.routes.url_helpers
  end
end
