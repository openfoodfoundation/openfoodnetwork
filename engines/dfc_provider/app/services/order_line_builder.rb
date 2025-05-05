# frozen_string_literal: true

class OrderLineBuilder < DfcBuilder
  def self.build(dfc_order, ofn_line_item)
    DataFoodConsortium::Connector::OrderLine.new(
      "#{dfc_order.semanticId}/OrderLines/#{ofn_line_item.id}",
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
