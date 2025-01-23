# frozen_string_literal: true

class SuppliedProductImporter < DfcBuilder
  def self.store_product(subject, enterprise)
    return unless subject.is_a? DataFoodConsortium::Connector::SuppliedProduct

    variant = import_variant(subject, enterprise)
    product = variant.product

    product.save! if product.new_record?
    variant.save! if variant.new_record?

    variant
  end

  def self.update_product(supplied_product, variant)
    apply(supplied_product, variant)

    variant.product.save!
    variant.save!

    variant
  end

  def self.import_variant(supplied_product, supplier)
    product = referenced_spree_product(supplied_product, supplier)

    if product
      Spree::Variant.new( product:, supplier:, price: 0,).tap do |variant|
        apply(supplied_product, variant)
      end
    else
      product = import_product(supplied_product, supplier)
      product.variants.first.tap { |variant| apply(supplied_product, variant) }
    end.tap do |variant|
      link = supplied_product.semanticId
      variant.semantic_links.new(semantic_id: link) if link.present?
    end
  end

  def self.referenced_spree_product(supplied_product, supplier)
    uri = supplied_product.spree_product_uri
    id = supplied_product.spree_product_id

    if uri.present?
      route = Rails.application.routes.recognize_path(uri)
      params = Rack::Utils.parse_nested_query(URI.parse(uri).query)

      # Check that the given URI points to us:
      return unless uri == urls.enterprise_url(route.merge(params))

      supplier.supplied_products.find_by(id: params["spree_product_id"])
    elsif id.present?
      supplier.supplied_products.find_by(id:)
    end
  end

  def self.import_product(supplied_product, supplier)
    Spree::Product.new(
      name: supplied_product.name,
      description: supplied_product.description,
      price: 0, # will be in DFC Offer
      supplier_id: supplier.id,
      primary_taxon_id: taxon(supplied_product).id,
      image: ImageBuilder.import(supplied_product.image),
    ).tap do |product|
      QuantitativeValueBuilder.apply(supplied_product.quantity, product)
      product.ensure_standard_variant
    end
  end

  def self.apply(supplied_product, variant)
    variant.product.assign_attributes(description: supplied_product.description)

    variant.display_name = supplied_product.name
    variant.primary_taxon = taxon(supplied_product)
    QuantitativeValueBuilder.apply(supplied_product.quantity, variant)

    catalog_item = supplied_product&.catalogItems&.first
    offer = catalog_item&.offers&.first
    CatalogItemBuilder.apply_stock(catalog_item, variant)
    OfferBuilder.apply(offer, variant)
  end

  def self.taxon(supplied_product)
    ProductTypeImporter.taxon(supplied_product.productType)
  end

  private_class_method :taxon
end
