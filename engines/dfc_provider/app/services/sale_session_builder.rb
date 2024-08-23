# frozen_string_literal: true

class SaleSessionBuilder < DfcBuilder
  def self.build(order_cycle)
    DataFoodConsortium::Connector::SaleSession.new(
      nil,
      beginDate: stringify_time(order_cycle&.orders_open_at),
      endDate: stringify_time(order_cycle&.orders_close_at),
    )
  end

  # This should be a standard JSON format but for now we format it the same
  # way as the FDC because that's the only way they can parse it.
  # Example: Thu Aug 22 2024 05:40:38 UTC
  def self.stringify_time(time)
    time&.utc&.strftime("%a %b %d %Y %H:%M:%S %Z")
  end
end
