# frozen_string_literal: true

# Service used to fetch variants related to an enterprise.
# It improves maintenance as it is the central point requesting
# Spree::Variant inside the DfcProvider engine.
class VariantFetcher
  def initialize(enterprise)
    @enterprise = enterprise
  end

  def scope
    @enterprise.supplied_variants
  end
end
