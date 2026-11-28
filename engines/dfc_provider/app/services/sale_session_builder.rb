# frozen_string_literal: true

class SaleSessionBuilder < DfcBuilder
  def self.build(order_cycle)
    DataFoodConsortium::ConnectorV1::SaleSession.new(
      nil,
      beginDate: stringify_time(order_cycle&.orders_open_at),
      endDate: stringify_time(order_cycle&.orders_close_at),
    )
  end

  # The session of one order cycle in one shop: the opening and closing dates
  # of the cycle and the offers of the variants that this shop sells in it.
  def self.for_cycle(order_cycle, distributor)
    build(order_cycle).tap do |session|
      session.semanticId = urls.enterprise_sale_session_url(
        enterprise_id: distributor.id,
        id: order_cycle.id,
      )
      session.offers = offers(order_cycle, distributor, session.semanticId)
    end
  end

  def self.offers(order_cycle, distributor, session_id)
    builder = CycleOfferBuilder.new(distributor, order_cycle)

    order_cycle.variants_distributed_by(distributor).map do |variant|
      builder.build(variant, session_id)
    end
  end

  # This should be a standard JSON format but for now we format it the same
  # way as the FDC because that's the only way they can parse it.
  # Example: Thu Aug 22 2024 05:40:38 UTC
  def self.stringify_time(time)
    time&.utc&.strftime("%a %b %d %Y %H:%M:%S %Z")
  end
end
