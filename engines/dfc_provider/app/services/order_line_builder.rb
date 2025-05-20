# frozen_string_literal: true

class OrderLineBuilder < DfcBuilder
  def self.build(ofn_line_item, semantic_id)
    DataFoodConsortium::Connector::OrderLine.new(
      semantic_id,
      offer: OfferBuilder.build(ofn_line_item.variant),
      quantity: ofn_line_item.quantity,
    )
  end

  def self.build_from_offer(offer, quantity)
    DataFoodConsortium::Connector::OrderLine.new(
      nil, offer:, quantity:,
    )
  end
end
