Spree::Classification.class_eval do
  belongs_to :product, :class_name => "Spree::Product", touch: true
  after_save :refresh_products_cache
  before_destroy :dont_destroy_if_primary_taxon
  after_destroy :refresh_products_cache


  private

  def refresh_products_cache
    product.refresh_products_cache
  end

  def dont_destroy_if_primary_taxon
    if product.primary_taxon == taxon
      errors.add :base,  I18n.t(:spree_classification_primary_taxon_error, taxon: taxon.name, product: product.name)
      return false
    end
  end
end
