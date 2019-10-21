Spree::Classification.class_eval do
  belongs_to :product, class_name: "Spree::Product", touch: true

  before_destroy :dont_destroy_if_primary_taxon

  private

  def dont_destroy_if_primary_taxon
    if product.primary_taxon == taxon
      errors.add :base, I18n.t(:spree_classification_primary_taxon_error, taxon: taxon.name, product: product.name)
      false
    end
  end
end
