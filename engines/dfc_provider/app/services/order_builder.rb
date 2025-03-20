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

  def self.apply(ofn_order, dfc_order)
    # Set order state if recognised
    ofn_order.state = "complete" if dfc_order.orderStatus == order_states.HELD

    dfc_order.lines.each do |order_line|
      # We don't need to look at the DFC object, we know the ID is a local variant ID.
      variant_id = order_line.offer.offeredItem.split('/supplied_products/').last

      ofn_order.line_items.build(
        variant_id:,
        quantity: order_line.quantity
      )
    end

    ofn_order.save
  end

  def self.order_states
    DfcLoader.vocabulary("vocabulary").STATES.ORDERSTATE
  end
end
