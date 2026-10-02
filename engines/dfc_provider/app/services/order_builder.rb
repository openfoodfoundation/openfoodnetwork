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
      orderStatus: order_status(ofn_order),
    )
  end

  # A backorder stays "Held" until the order cycle closes and the client
  # completes it. We don't record that distinction on an OFN order yet, so we
  # report the one status we can be sure about. The client (see
  # FdcBackorderer#lookup_open_order) relies on "Held" to find its open orders.
  def self.order_status(ofn_order)
    ofn_order.state == "canceled" ? "dfc-v:Cancelled" : "dfc-v:Held"
  end

  # Applies a DFC order to an OFN order.
  #
  # Line items are applied before the order status because completing an order
  # changes how line items are saved: `Spree::OrderInventory` only assigns
  # inventory units for orders that are already complete.
  #
  # Returns false and leaves the order untouched if the payload is invalid.
  def self.apply(ofn_order, dfc_order, variant_scope: Spree::Variant)
    attrs, stale_ids, unknown =
      OrderLineItemsBuilder.attributes(ofn_order, dfc_order, variant_scope)

    if unknown.any?
      ofn_order.errors.add(:line_items, "reference unknown products: #{unknown.join(', ')}")
      return false
    end

    ofn_order.transaction do
      ofn_order.update!(line_items_attributes: attrs)
      destroy_stale_line_items(ofn_order, stale_ids)
      apply_order_status(ofn_order, dfc_order)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def self.apply_order_status(ofn_order, dfc_order)
    case dfc_order.orderStatus
    when order_states.HELD, order_states.COMPLETE
      complete(ofn_order)
    when order_states.CANCELLED
      cancel(ofn_order)
    end
  end

  # An order we received is a real order: it needs a shipment so that stock is
  # reserved, and `completed_at` so that the rest of OFN treats it as placed.
  # Without `completed_at` it would show up as the ordering user's shopping
  # cart (`Spree::User#last_incomplete_spree_order`) and could never be
  # cancelled (`Spree::Order#allow_cancel?`).
  def self.complete(ofn_order)
    return if ofn_order.completed?
    return if ofn_order.line_items.empty?

    ofn_order.create_proposed_shipments
    ofn_order.state = "complete"
    ofn_order.finalize!
  end

  def self.cancel(ofn_order)
    ofn_order.send_cancellation_email = false
    ofn_order.cancel! if ofn_order.allow_cancel?
  end

  def self.destroy_stale_line_items(ofn_order, stale_ids)
    # `accepts_nested_attributes_for :line_items` does not permit `:_destroy`,
    # so remove line items that are no longer present explicitly.
    return if stale_ids.empty?

    ofn_order.line_items.where(id: stale_ids).destroy_all

    # `destroy_all` on the association relation doesn't update the parent's
    # loaded collection. Tax adjustments would then be recalculated against
    # deleted line items.
    ofn_order.line_items.reload
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
