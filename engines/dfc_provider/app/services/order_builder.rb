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

    attrs = line_item_attributes(ofn_order, dfc_order)
    destroy_stale_line_items(ofn_order, attrs)

    ofn_order.update(line_items_attributes: attrs.reject { |a| a[:_destroy] })
  end

  def self.set_order_state(ofn_order, dfc_order)
    ofn_order.state = "complete" if dfc_order.orderStatus == order_states.HELD
    ofn_order.completed_at ||= Time.zone.now if dfc_order.orderStatus == order_states.COMPLETE
  end

  def self.destroy_stale_line_items(ofn_order, attrs)
    # `accepts_nested_attributes_for :line_items` does not permit `:_destroy`,
    # so remove line items that are no longer present explicitly.
    stale_ids = attrs.filter_map { |a| a[:id] if a[:_destroy] }
    ofn_order.line_items.where(id: stale_ids).destroy_all if stale_ids.any?
  end

  def self.line_item_attributes(ofn_order, dfc_order)
    incoming = dfc_order.lines.each_with_object({}) do |line, hash|
      next if line.quantity.nil? || line.quantity <= 0

      vid = line.offer.offeredItem.split('/supplied_products/').last
      hash[vid.to_i] = line.quantity
    end

    ofn_order.line_items.each_with_object([]) do |li, arr|
      arr << if incoming.key?(li.variant_id)
               { id: li.id, quantity: incoming.delete(li.variant_id) }
             else
               { id: li.id, _destroy: true }
             end
    end.tap do |attrs|
      incoming.each do |variant_id, quantity|
        attrs << { variant_id:, quantity: }
      end
    end
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
