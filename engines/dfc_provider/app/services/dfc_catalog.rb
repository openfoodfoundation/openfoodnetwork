# frozen_string_literal: true

class DfcCatalog
  def self.load(user, catalog_url)
    api = DfcRequest.new(user)
    catalog_json = api.call(catalog_url)

    from_json(catalog_json)
  end

  def self.from_json(catalog_json)
    new(DfcIo.import(catalog_json))
  end

  def initialize(graph)
    @graph = graph
  end

  # List all products in this catalog.
  # These are SuppliedProduct objects which may be grouped as variants.
  # But we don't return the parent products having variants.
  def products
    @products ||= @graph.select do |subject|
      subject.is_a?(DataFoodConsortium::Connector::SuppliedProduct) &&
        subject.variants.blank?
    end
  end

  def item(semantic_id)
    @items ||= @graph.index_by(&:semanticId)
    @items[semantic_id]
  end

  def select_type(semantic_type)
    @graph.select { |i| i.semanticType == semantic_type }
  end

  def apply_wholesale_values!
    broker = FdcOfferBroker.new(self)
    products.each do |product|
      transformation = broker.best_offer(product.semanticId)

      next if transformation.factor == 1

      adjust_to_wholesale_price(product, transformation)
      adjust_to_wholesale_stock(product, transformation)
    end
  end

  private

  def adjust_to_wholesale_price(product, transformation)
    wholesale_variant_price = transformation.offer.price

    return unless wholesale_variant_price

    offer = product.catalogItems&.first&.offers&.first

    return unless offer

    offer.price = wholesale_variant_price.dup
    offer.price.value = offer.price.value.to_f / transformation.factor
  end

  def adjust_to_wholesale_stock(product, transformation)
    adjust_item_stock(product, transformation)
    adjust_offer_stock(product, transformation)
  end

  def adjust_item_stock(product, transformation)
    item = product.catalogItems&.first
    wholesale_item = transformation.product.catalogItems&.first

    return unless item && wholesale_item&.stockLimitation.present?

    item.stockLimitation = wholesale_item.stockLimitation.to_i * transformation.factor
  end

  def adjust_offer_stock(product, transformation)
    offer = product.catalogItems&.first&.offers&.first
    wholesale_offer = transformation.offer

    return unless offer && wholesale_offer&.stockLimitation.present?

    offer.stockLimitation = wholesale_offer.stockLimitation.to_i * transformation.factor
  end
end
