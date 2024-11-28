# frozen_string_literal: true

# When orders are cancelled, we need to amend
# an existing backorder as well.
# We're not dealing with line item changes just yet.
class AmendBackorderJob < ApplicationJob
  sidekiq_options retry: 0

  def perform(order)
    OrderLocker.lock_order_and_variants(order) do
      amend_backorder(order)
    end
  end

  # The following is a mix of the BackorderJob and the CompleteBackorderJob.
  # TODO: Move the common code into a re-usable service class.
  def amend_backorder(order)
    order_cycle = order.order_cycle
    distributor = order.distributor
    user = distributor.owner
    items = backorderable_items(order)

    return if items.empty?

    # We are assuming that all variants are linked to the same wholesale
    # shop and its catalog:
    reference_link = items[0].variant.semantic_links[0].semantic_id
    urls = FdcUrlBuilder.new(reference_link)
    orderer = FdcBackorderer.new(user, urls)

    backorder = orderer.find_open_order(order)

    variants = order_cycle.variants_distributed_by(distributor)
    adjust_quantities(order_cycle, user, backorder, urls, variants)

    FdcBackorderer.new(user, urls).send_order(backorder)
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

  # We look at all linked variants.
  def backorderable_items(order)
    order.line_items.select do |item|
      # TODO: scope variants to hub.
      # We are only supporting producer stock at the moment.
      item.variant.semantic_links.present?
    end
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
