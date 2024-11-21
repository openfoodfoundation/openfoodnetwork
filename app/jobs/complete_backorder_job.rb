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

    variants = order_cycle.variants_distributed_by(distributor)
    adjust_quantities(order_cycle, user, order, urls, variants)

    FdcBackorderer.new(user, urls).complete_order(order)

    exchange = order_cycle.exchanges.outgoing.find_by(receiver: distributor)
    exchange.semantic_links.find_by(semantic_id: order_id)&.destroy!
  rescue StandardError
    BackorderMailer.backorder_incomplete(user, distributor, order_cycle, order_id).deliver_later

    raise
  end

  # Check if we have enough stock to reduce the backorder.
  #
  # Our local stock can increase when users cancel their orders.
  # But stock levels could also have been adjusted manually. So we review all
  # quantities before finalising the order.
  def adjust_quantities(order_cycle, user, order, urls, variants)
    broker = FdcOfferBroker.new(user, urls)

    order.lines.each do |line|
      line.quantity = line.quantity.to_i
      wholesale_product_id = line.offer.offeredItem.semanticId
      transformation = broker.wholesale_to_retail(wholesale_product_id)
      linked_variant = variants.linked_to(transformation.retail_product_id)

      # Assumption: If a transformation is present then we only sell the retail
      # variant. If that can't be found, it was deleted and we'll ignore that
      # for now.
      next if linked_variant.nil?

      # Find all line items for this order cycle
      # Update quantity accordingly
      if linked_variant.on_demand
        release_superfluous_stock(line, linked_variant, transformation)
      else
        aggregate_final_quantities(order_cycle, line, linked_variant, transformation)
      end
    end

    # Clean up empty lines:
    order.lines.reject! { |line| line.quantity.zero? }
  end

  def release_superfluous_stock(line, linked_variant, transformation)
    # Note that a division of integers dismisses the remainder, like `floor`:
    wholesale_items_contained_in_stock = linked_variant.on_hand / transformation.factor

    # But maybe we didn't actually order that much:
    deductable_quantity = [line.quantity, wholesale_items_contained_in_stock].min
    line.quantity -= deductable_quantity

    retail_stock_changes = deductable_quantity * transformation.factor
    linked_variant.on_hand -= retail_stock_changes
  end

  def aggregate_final_quantities(order_cycle, line, variant, transformation)
    orders = order_cycle.orders.invoiceable
    quantity = Spree::LineItem.where(order: orders, variant:).sum(:quantity)
    wholesale_quantity = (quantity.to_f / transformation.factor).ceil
    line.quantity = wholesale_quantity
  end
end
