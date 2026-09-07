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

    status = case ofn_order.state
             when "canceled" then "dfc-v:Cancelled"
             when "complete" then "dfc-v:Complete"
             else "dfc-v:Held"
             end

    DataFoodConsortium::ConnectorV1::Order.new(
      id,
      client: urls.enterprise_url(ofn_order.distributor_id),
      orderStatus: status,
    )
  end

  def self.apply(ofn_order, dfc_order, enterprise = nil)
    enterprise ||= ofn_order.distributor
    incoming = incoming_quantities(dfc_order, enterprise)
    attrs, stale_ids = build_line_item_attributes(ofn_order, incoming)

    ofn_order.transaction do
      # For new records, save empty first inside transaction to avoid
      # products_available_from_new_distribution and to allow rollback
      if ofn_order.new_record?
        ofn_order.state = "cart" unless ofn_order.state == "cart"
        ofn_order.completed_at = nil
        ofn_order.save!
      end

      ofn_order.assign_attributes(line_items_attributes: attrs)
      destroy_stale_line_items(ofn_order, stale_ids) if stale_ids.any?

      ofn_order.save!

      # Now set order state after line items exist
      set_order_state(ofn_order, dfc_order)
      ofn_order.save! if ofn_order.changed?
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def self.set_order_state(ofn_order, dfc_order)
    case dfc_order.orderStatus
    when order_states.HELD, order_states.COMPLETE
      ofn_order.state = "complete" if ofn_order.state != "complete"
      ofn_order.completed_at ||= Time.zone.now
    end
  end

  def self.destroy_stale_line_items(ofn_order, stale_ids)
    # `accepts_nested_attributes_for :line_items` does not permit `:_destroy`,
    # so remove line items that are no longer present explicitly.
    ofn_order.line_items.where(id: stale_ids).destroy_all if stale_ids.any?
  end

  def self.incoming_quantities(dfc_order, _enterprise = nil)
    dfc_order.lines.each_with_object(Hash.new(0)) do |line, hash|
      next if line.quantity.nil? || line.quantity <= 0
      next if line.offer&.offeredItem.nil?

      sid = semantic_id(line.offer.offeredItem)
      vid = sid.split(%r{/supplied_products/}i).last.to_i
      hash[vid] += line.quantity.to_i
    end
  end

  def self.build_line_item_attributes(ofn_order, incoming)
    attrs = []
    stale_ids = []

    ofn_order.line_items.each do |li|
      if incoming.key?(li.variant_id)
        # Update existing line items
        attrs << { id: li.id, quantity: incoming.delete(li.variant_id) }
      else
        # Delete line items that weren't provided
        stale_ids << li.id
      end
    end

    # Create any new line items
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
