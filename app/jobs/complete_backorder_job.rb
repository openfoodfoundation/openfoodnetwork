# frozen_string_literal: true

# After an order cycle closed, we need to finalise open draft orders placed
# to replenish stock.
class CompleteBackorderJob < ApplicationJob
  sidekiq_options retry: 0

  # Required parameters:
  #
  # * user: to authenticate DFC requests
  # * distributor: to reconile with its catalog
  # * order_cycle: to scope the catalog when looking up variants
  #                Multiple variants can be linked to the same remote product.
  #                To reduce ambiguity, we'll reconcile only with products
  #                from the given distributor in a given order cycle for which
  #                the remote backorder was placed.
  # * order_id: the remote semantic id of a draft order
  #             Having the id makes sure that we don't accidentally finalise
  #             someone else's order.
  def perform(user, distributor, order_cycle, order_id)
    order = FdcBackorderer.new(user, nil).find_order(order_id)

    return if order&.lines.blank?

    urls = FdcUrlBuilder.new(order.lines[0].offer.offeredItem.semanticId)

    BackorderUpdater.new.update(order, user, distributor, order_cycle)

    FdcBackorderer.new(user, urls).complete_order(order)

    exchange = order_cycle.exchanges.outgoing.find_by(receiver: distributor)
    exchange.semantic_links.find_by(semantic_id: order_id)&.destroy!
  rescue StandardError
    BackorderMailer.backorder_incomplete(user, distributor, order_cycle, order_id).deliver_later

    raise
  end
end
