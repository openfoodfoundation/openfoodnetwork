# frozen_string_literal: true

class ProductTypeImporter < DfcBuilder
  def self.taxon(product_type)
    dfc_id = product_type&.semanticId

    # Every product needs a primary taxon to be valid. So if we don't have
    # one or can't find it we just take a random one.
    Spree::Taxon.find_by(dfc_id:) || Spree::Taxon.first
  end
end
