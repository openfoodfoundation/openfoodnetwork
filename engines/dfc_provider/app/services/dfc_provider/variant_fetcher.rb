# frozen_string_literal: true

# Service used to fetch variants related to an entreprise.
# It improves maintenance as it is the central point requesting
# Spree::Varaint inside the DfcProvider engine.
module DfcProvider
  class VariantFetcher
    def initialize(enterprise)
      @enterprise = enterprise
    end

    def scope
      Spree::Variant.
        joins(product: :supplier).
        where('enterprises.id' => @enterprise.id)
    end
  end
end
