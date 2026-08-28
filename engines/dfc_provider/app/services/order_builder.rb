# frozen_string_literal: true

class OrderBuilder < DfcBuilder
  def self.new_order(ofn_order, id = nil)
    DataFoodConsortium::ConnectorV1::Order.new(
      id,
      client: urls.enterprise_url(ofn_order.distributor_id),
      orderStatus: "dfc-v:Held",
    )
  end

  def self.build(ofn_order)
    id = urls.enterprise_order_url(
      enterprise_id: ofn_order.distributor_id,
      id: ofn_order.id,
    )

    DataFoodConsortium::ConnectorV1::Order.new(
      id,
      client: urls.enterprise_url(ofn_order.distributor_id),
      orderStatus: "dfc-v:Held",
    )
  end

  def self.apply(ofn_order, dfc_order)
    # Set order state if recognised
    set_order_state(ofn_order, dfc_order)

    attrs, stale_ids = line_item_attributes(ofn_order, dfc_order)
    destroy_stale_line_items(ofn_order, stale_ids)

    ofn_order.update(line_items_attributes: attrs)
  end

  def self.set_order_state(ofn_order, dfc_order)
    ofn_order.state = "complete" if dfc_order.orderStatus == order_states.HELD
    ofn_order.completed_at ||= Time.zone.now if dfc_order.orderStatus == order_states.COMPLETE
  end

  def self.destroy_stale_line_items(ofn_order, stale_ids)
    # `accepts_nested_attributes_for :line_items` does not permit `:_destroy`,
    # so remove line items that are no longer present explicitly.
    ofn_order.line_items.where(id: stale_ids).destroy_all if stale_ids.any?
  end

  def self.line_item_attributes(ofn_order, dfc_order)
    incoming = incoming_quantities(dfc_order)
    build_line_item_attributes(ofn_order, incoming)
  end

  def self.incoming_quantities(dfc_order)
    dfc_order.lines.each_with_object({}) do |line, hash|
      next if line.quantity.nil? || line.quantity <= 0
      next if line.offer&.offeredItem.nil?

      vid = semantic_id(line.offer.offeredItem).split(%r{/supplied_products/}i).last
      hash[vid.to_i] = line.quantity
    end
  end

  def self.build_line_item_attributes(ofn_order, incoming)
    attrs = []
    stale_ids = []

    ofn_order.line_items.each do |li|
      if incoming.key?(li.variant_id)
        attrs << { id: li.id, quantity: incoming.delete(li.variant_id) }
      else
        stale_ids << li.id
      end
    end

    incoming.each do |variant_id, quantity|
      attrs << { variant_id:, quantity: }
    end

    [attrs, stale_ids]
  end

  def self.order_states
    DfcLoader.vocabulary("vocabulary").STATES.ORDERSTATE
  end

  def self.build_order_lines(dfc_order, ofn_line_items)
    dfc_order.lines = ofn_line_items.map do |line_item|
      OrderLineBuilder.build(dfc_order, line_item).tap do |order_line|
        OfferBuilder.add_offered_item(order_line.offer, line_item.variant)
      end
    end
  end
end
