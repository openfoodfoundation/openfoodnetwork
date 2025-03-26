# frozen_string_literal: true

class OrderBuilder < DfcBuilder
  def self.build(ofn_order)
    id = urls.enterprise_order_url(
      enterprise_id: ofn_order.distributor_id,
      id: ofn_order.id,
    )

    DataFoodConsortium::Connector::Order.new(
      id,
      client: urls.enterprise_url(ofn_order.distributor_id),
      orderStatus: "dfc-v:Held",
    )
  end

  def self.new_order(ofn_order, id = nil)
    DataFoodConsortium::Connector::Order.new(
      id,
      client: urls.enterprise_url(ofn_order.distributor_id),
      orderStatus: "dfc-v:Held",
    )
  end

  def self.apply(ofn_order, dfc_order, graph)
    # Set order state if recognised
    ofn_order.state = "complete" if dfc_order.orderStatus == order_status.HELD

    # build line items
    dfc_order.lines.each do |orderLine|
      # dfc_product = find(graph, dfc_order.lines.first.offer.offeredItem)
      # variant_id = SemanticLink.where(
      #   subject_type: "Spree::Variant",
      #   semantic_id: dfc_order.lines.first.offer.offeredItem
      # ).pluck(:id).first
      variant_id = dfc_order.lines.first.offer.offeredItem.split('/supplied_products/').last

      ofn_order.line_items.create(variant_id:)
    end

    ofn_order.save
  end

  def self.order_status
    DfcLoader.vocabulary("vocabulary").STATES.ORDERSTATE
  end

  # todo: dedup with DfcCatalog.item into new DfcGraph
  def self.find(graph, semantic_id)
    @items ||= graph.index_by(&:semanticId)
    @items[semantic_id]
  end
end
