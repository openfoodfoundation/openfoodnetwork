# frozen_string_literal: true

class OrderLineBuilder < DfcBuilder
  def self.build(offer, quantity)
    DataFoodConsortium::Connector::OrderLine.new(
      nil, offer:, quantity:,
    )
  end
end
