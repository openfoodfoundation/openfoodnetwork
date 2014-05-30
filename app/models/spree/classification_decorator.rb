Spree::Classification.class_eval do
  before_destroy :dont_destroy_if_primary_taxon

  def dont_destroy_if_primary_taxon
    if product.primary_taxon == taxon
      errors.add :base,  "Taxon #{taxon.name} is the primary taxon of #{product.name} and cannot be deleted"
      return false
    end
  end
end
