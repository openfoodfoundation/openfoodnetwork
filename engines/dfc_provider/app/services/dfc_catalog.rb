# frozen_string_literal: true

class DfcCatalog
  def self.load(user, catalog_url)
    api = DfcRequest.new(user)
    catalog_json = api.call(catalog_url)
    graph = DfcIo.import(catalog_json)

    new(graph)
  end

  def initialize(graph)
    @graph = graph
  end

  def products
    @products ||= @graph.select do |subject|
      subject.is_a? DataFoodConsortium::Connector::SuppliedProduct
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
      adjust_to_wholesale_price(broker, product)
    end
  end

  private

  def adjust_to_wholesale_price(broker, product)
    transformation = broker.best_offer(product.semanticId)

    return if transformation.factor == 1

    wholesale_variant_price = transformation.offer.price

    return unless wholesale_variant_price

    offer = product.catalogItems&.first&.offers&.first

    return unless offer

    offer.price = wholesale_variant_price.dup
    offer.price.value = offer.price.value.to_f / transformation.factor
  end
end
