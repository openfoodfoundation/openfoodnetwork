# frozen_string_literal: true

# After an order cycle closed, we need to finalise open draft orders placed
# to replenish stock.
class CompleteBackorderJob < ApplicationJob
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
    service = FdcBackorderer.new(user)
    order = service.find_order(order_id)

    variants = order_cycle.variants_distributed_by(distributor)
    adjust_quantities(user, order, variants)

    service.complete_order(order)
  end

  # Check if we have enough stock to reduce the backorder.
  #
  # Our local stock can increase when users cancel their orders.
  # But stock levels could also have been adjusted manually. So we review all
  # quantities before finalising the order.
  def adjust_quantities(user, order, variants)
    broker = FdcOfferBroker.new(BackorderJob.load_catalog(user))

    order.lines.each do |line|
      wholesale_product_id = line.offer.offeredItem.semanticId
      transformation = broker.wholesale_to_retail(wholesale_product_id)
      linked_variant = variants.linked_to(transformation.retail_product_id)

      # Note that a division of integers dismisses the remainder, like `floor`:
      wholesale_items_contained_in_stock = linked_variant.on_hand / transformation.factor
      line.quantity = line.quantity.to_i - wholesale_items_contained_in_stock

      retail_stock_changes = wholesale_items_contained_in_stock * transformation.factor
      linked_variant.on_hand -= retail_stock_changes
    end
  end
end
