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
end
