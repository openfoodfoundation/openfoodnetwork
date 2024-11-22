# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

# When orders are created, adjusted or cancelled, we need to amend
# an existing backorder as well.
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
    variants = distributed_linked_variants(order)
    return unless variants.any?

    user = order.distributor.owner
    order_cycle = order.order_cycle

    # We are assuming that all variants are linked to the same wholesale
    # shop and its catalog:
    reference_link = variants[0].semantic_links[0].semantic_id
    urls = FdcUrlBuilder.new(reference_link)
    orderer = FdcBackorderer.new(user, urls)
    broker = FdcOfferBroker.new(user, urls)

    backorder = orderer.find_open_order(order)

    updated_lines = update_order_lines(backorder, order_cycle, variants, broker, orderer)
    unprocessed_lines = backorder.lines.to_set - updated_lines
    cancel_stale_lines(unprocessed_lines, order, broker)

    # Clean up empty lines:
    backorder.lines.reject! { |line| line.quantity.zero? }

    FdcBackorderer.new(user, urls).send_order(backorder)
  end

  def update_order_lines(backorder, order_cycle, variants, broker, orderer)
    variants.map do |variant|
      link = variant.semantic_links[0].semantic_id
      solution = broker.best_offer(link)
      line = orderer.find_or_build_order_line(backorder, solution.offer)
      if variant.on_demand
        adjust_stock(variant, solution, line)
      else
        aggregate_final_quantities(order_cycle, line, variant, solution)
      end

      line
    end
  end

  def cancel_stale_lines(unprocessed_lines, order, broker)
    managed_variants = managed_linked_variants(order)
    unprocessed_lines.each do |line|
      wholesale_quantity = line.quantity.to_i
      wholesale_product_id = line.offer.offeredItem.semanticId
      transformation = broker.wholesale_to_retail(wholesale_product_id)
      linked_variant = managed_variants.linked_to(transformation.retail_product_id)

      if linked_variant.nil?
        transformation.factor = 1
        linked_variant = managed_variants.linked_to(wholesale_product_id)
      end

      # Adjust stock level back, we're not going to order this one.
      if linked_variant&.on_demand
        retail_quantity = wholesale_quantity * transformation.factor
        linked_variant.on_hand -= retail_quantity
      end

      # We don't have any active orders for this
      line.quantity = 0
    end
  end

  def adjust_stock(variant, solution, line)
    if variant.on_hand.negative?
      needed_quantity = -1 * variant.on_hand # We need to replenish it.

      # The number of wholesale packs we need to order to fulfill the
      # needed quantity.
      # For example, we order 2 packs of 12 cans if we need 15 cans.
      wholesale_quantity = (needed_quantity.to_f / solution.factor).ceil

      # The number of individual retail items we get with the wholesale order.
      # For example, if we order 2 packs of 12 cans, we will get 24 cans
      # and we'll account for that in our stock levels.
      retail_quantity = wholesale_quantity * solution.factor

      line.quantity = line.quantity.to_i + wholesale_quantity
      variant.on_hand += retail_quantity
    else
      # Note that a division of integers dismisses the remainder, like `floor`:
      wholesale_items_contained_in_stock = variant.on_hand / solution.factor

      # But maybe we didn't actually order that much:
      deductable_quantity = [line.quantity, wholesale_items_contained_in_stock].min

      if deductable_quantity.positive?
        line.quantity -= deductable_quantity

        retail_stock_change = deductable_quantity * solution.factor
        variant.on_hand -= retail_stock_change
      end
    end
  end

  def managed_linked_variants(order)
    user = order.distributor.owner
    order_cycle = order.order_cycle

    # These permissions may be too complex. Here may be scope to optimise.
    permissions = OpenFoodNetwork::OrderCyclePermissions.new(user, order_cycle)
    permissions.visible_variants_for_outgoing_exchanges_to(order.distributor)
      .where.associated(:semantic_links)
  end

  def distributed_linked_variants(order)
    order.order_cycle.variants_distributed_by(order.distributor)
      .where.associated(:semantic_links)
  end

  def aggregate_final_quantities(order_cycle, line, variant, transformation)
    # We may want to query all these quantities in one go instead of this n+1.
    orders = order_cycle.orders.invoiceable
    quantity = Spree::LineItem.where(order: orders, variant:).sum(:quantity)
    wholesale_quantity = (quantity.to_f / transformation.factor).ceil
    line.quantity = wholesale_quantity
  end
end
