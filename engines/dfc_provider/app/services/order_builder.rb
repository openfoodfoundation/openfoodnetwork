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
  # Nothing is written to the database here: the order and its line items are
  # only changed in memory, so that several `apply` calls can be composed into
  # a single save. The caller persists the result with `finalise`, which also
  # runs inside the caller's transaction.
  #
  # Returns false and leaves the order untouched if the payload is invalid.
  #
  # rubocop:disable-next Naming/PredicateMethod
  def self.apply(ofn_order, dfc_order, variant_scope: Spree::Variant)
    attrs, unknown = OrderLineItemsBuilder.attributes(ofn_order, dfc_order, variant_scope)

    if unknown.any?
      ofn_order.errors.add(:line_items, "reference unknown products: #{unknown.join(', ')}")
      return false
    end

    ofn_order.line_items_attributes = attrs

    true
  end

  # Persists an order that `apply` has already changed in memory, and gives it
  # the state the client asked for. This writes to the database, so it is the
  # controller's responsibility to wrap it in a transaction.
  def self.finalise(ofn_order, dfc_order)
    if cancels?(dfc_order)
      ofn_order.send_cancellation_email = false
      ofn_order.cancel! if ofn_order.allow_cancel?
    elsif completes?(dfc_order)
      complete(ofn_order)
    end
  end

  def self.completes?(dfc_order)
    [order_states.HELD, order_states.COMPLETE].include?(dfc_order.orderStatus)
  end

  def self.cancels?(dfc_order)
    dfc_order.orderStatus == order_states.CANCELLED
  end

  # A backorder is a real order: it needs a shipment so that stock is
  # reserved, and `completed_at` so that the rest of OFN treats it as placed.
  # Without `completed_at` it would show up as the ordering user's shopping
  # cart (`Spree::User#last_incomplete_spree_order`) and could never be
  # cancelled (`Spree::Order#allow_cancel?`).
  #
  # The shipment has to be built from saved line items, which is why this runs
  # after the order has been persisted.
  def self.complete(ofn_order)
    return if ofn_order.completed?
    return if ofn_order.line_items.empty?

    ofn_order.create_proposed_shipments
    ofn_order.state = "complete"
    ofn_order.finalize!
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
