# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

# Update a backorder to reflect all local orders and stock levels
# connected to the associated order cycle.
class BackorderUpdater
  # Given an OFN order was created, changed or cancelled,
  # we re-calculate how much to order in for every variant.
  def amend_backorder(order)
    order_cycle = order.order_cycle
    distributor = order.distributor
    variants = distributed_linked_variants(order_cycle, distributor)

    # Temporary code: once we don't need a variant link to look up the
    # backorder, we don't need this check anymore.
    # Then we can adjust the backorder even though there are no linked variants
    # in the order cycle right now. Some variants may have been in the order
    # cycle before and got ordered before being removed from the order cycle.
    return unless variants.any?

    # We are assuming that all variants are linked to the same wholesale
    # shop and its catalog:
    reference_link = variants[0].semantic_links[0].semantic_id
    user = order.distributor.owner
    urls = FdcUrlBuilder.new(reference_link)
    orderer = FdcBackorderer.new(user, urls)

    backorder = orderer.find_open_order(order)

    update(backorder, user, distributor, order_cycle) if backorder
  end

  # Update a given backorder according to a distributor's order cycle.
  def update(backorder, user, distributor, order_cycle)
    variants = distributed_linked_variants(order_cycle, distributor)

    # We are assuming that all variants are linked to the same wholesale
    # shop and its catalog:
    reference_link = variants[0].semantic_links[0].semantic_id
    urls = FdcUrlBuilder.new(reference_link)
    orderer = FdcBackorderer.new(user, urls)
    catalog = DfcCatalog.load(user, urls.catalog_url)
    broker = FdcOfferBroker.new(catalog)

    updated_lines = update_order_lines(backorder, order_cycle, variants, broker, orderer)
    unprocessed_lines = backorder.lines.to_set - updated_lines
    managed_variants = managed_linked_variants(user, order_cycle, distributor)
    cancel_stale_lines(unprocessed_lines, managed_variants, broker)

    # Clean up empty lines:
    backorder.lines.reject! { |line| line.quantity.zero? }

    backorder
  end

  def update_order_lines(backorder, order_cycle, variants, broker, orderer)
    variants.map do |variant|
      link = variant.semantic_links[0].semantic_id
      solution = broker.best_offer(link)

      next unless solution.offer

      line = orderer.find_or_build_order_line(backorder, solution.offer)
      if variant.on_demand
        adjust_stock(variant, solution, line)
      else
        aggregate_final_quantities(order_cycle, line, variant, solution)
      end

      line
    end.compact
  end

  def cancel_stale_lines(unprocessed_lines, managed_variants, broker)
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
    line.quantity = line.quantity.to_i

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

      line.quantity += wholesale_quantity
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

  def managed_linked_variants(user, order_cycle, distributor)
    # These permissions may be too complex. Here may be scope to optimise.
    permissions = OpenFoodNetwork::OrderCyclePermissions.new(user, order_cycle)
    permissions.visible_variants_for_outgoing_exchanges_to(distributor)
      .where.associated(:semantic_links)
  end

  def distributed_linked_variants(order_cycle, distributor)
    order_cycle.variants_distributed_by(distributor)
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
