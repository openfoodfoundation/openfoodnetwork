# frozen_string_literal: true

class SuppliedProductBuilder < DfcBuilder
  def self.supplied_product(variant)
    id = urls.enterprise_supplied_product_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )
    product_uri = urls.enterprise_url(
      variant.product.supplier_id,
      spree_product_id: variant.product_id
    )

    DfcProvider::SuppliedProduct.new(
      id,
      name: variant.product_and_full_name,
      description: variant.description,
      productType: product_type(variant),
      quantity: QuantitativeValueBuilder.quantity(variant),
      spree_product_uri: product_uri,
      spree_product_id: variant.product.id,
      image_url: variant.product&.image&.url(:product)
    )
  end

  def self.import_variant(supplied_product, supplier)
    product = referenced_spree_product(supplied_product, supplier)

    if product
      Spree::Variant.new(
        product:,
        price: 0,
      ).tap do |variant|
        apply(supplied_product, variant)
      end
    else
      product = import_product(supplied_product)
      product.supplier = supplier
      product.ensure_standard_variant
      product.variants.first
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

  def self.import_product(supplied_product)
    Spree::Product.new(
      name: supplied_product.name,
      description: supplied_product.description,
      price: 0, # will be in DFC Offer
      primary_taxon: taxon(supplied_product)
    ).tap do |product|
      QuantitativeValueBuilder.apply(supplied_product.quantity, product)
    end
  end

  def self.apply(supplied_product, variant)
    variant.product.assign_attributes(
      description: supplied_product.description,
      primary_taxon: taxon(supplied_product)
    )

    variant.display_name = supplied_product.name
    QuantitativeValueBuilder.apply(supplied_product.quantity, variant.product)
    variant.unit_value = variant.product.unit_value
  end

  def self.product_type(variant)
    taxon_dfc_id = variant.product.primary_taxon&.dfc_id

    DfcProductTypeFactory.for(taxon_dfc_id)
  end

  def self.taxon(supplied_product)
    dfc_id = supplied_product.productType.semanticId
    Spree::Taxon.find_by(dfc_id: )
  end

  private_class_method :product_type, :taxon
end
