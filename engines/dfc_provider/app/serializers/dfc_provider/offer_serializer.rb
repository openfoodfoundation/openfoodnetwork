# frozen_string_literal: true

# Serializer used to render the DFC Offer from an OFN Product
# into JSON-LD format based on DFC ontology
module DfcProvider
  class OfferSerializer
    def initialize(variant)
      @variant = variant
    end

    def serialized_data
      {
        "@id" => "offers/#{@variant.id}",
        "@type" => "dfc:Offer",
        "dfc:offeresTo" => {
          "@type" => "@id",
          "@id" => "/customerCategoryId1"
        },
        "dfc:price" => @variant.price,
        "dfc:stockLimitation" => @variant.total_on_hand,
      }
    end
  end
end
