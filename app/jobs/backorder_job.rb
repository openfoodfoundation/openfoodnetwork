# frozen_string_literal: true

class BackorderJob < ApplicationJob
  # In the current FDC project, one shop wants to review and adjust orders
  # before finalising. They also run a market stall and need to adjust stock
  # levels after the market. This should be done within four hours.
  SALE_SESSION_DELAYS = {
    # https://openfoodnetwork.org.uk/handleyfarm/shop
    "https://openfoodnetwork.org.uk/api/dfc/enterprises/203468" => 4.hours,
  }.freeze

  queue_as :default
  sidekiq_options retry: 0

  def self.check_stock(order)
    links = SemanticLink.where(subject: order.variants)

    perform_later(order) if links.exists?
  rescue StandardError => e
    # Errors here shouldn't affect the checkout. So let's report them
    # separately:
    Bugsnag.notify(e) do |payload|
      payload.add_metadata(:order, :order, order)
    end
  end

  def perform(order)
    OrderLocker.lock_order_and_variants(order) do
      place_backorder(order)
    end
  rescue StandardError
    # If the backordering fails, we need to tell the shop owner because they
    # need to organgise more stock.
    BackorderMailer.backorder_failed(order).deliver_later

    raise
  end

  def place_backorder(order)
    user = order.distributor.owner
    items = backorderable_items(order)

    return if items.empty?

    # We are assuming that all variants are linked to the same wholesale
    # shop and its catalog:
    reference_link = items[0].variant.semantic_links[0].semantic_id
    urls = FdcUrlBuilder.new(reference_link)
    orderer = FdcBackorderer.new(user, urls)

    backorder = orderer.find_or_build_order(order)
    broker = load_broker(order.distributor.owner, urls)
    ordered_quantities = {}

    items.each do |item|
      retail_quantity = add_item_to_backorder(item, broker, backorder, orderer)
      ordered_quantities[item] = retail_quantity
    end

    place_order(user, order, orderer, backorder)

    items.each do |item|
      variant = item.variant
      variant.on_hand += ordered_quantities[item] if variant.on_demand
    end
  end

  # We look at linked variants which are either stock controlled or
  # are on demand with negative stock.
  def backorderable_items(order)
    order.line_items.select do |item|
      # TODO: scope variants to hub.
      # We are only supporting producer stock at the moment.
      variant = item.variant
      variant.semantic_links.present? &&
        (variant.on_demand == false || variant.on_hand&.negative?)
    end
  end

  def add_item_to_backorder(line_item, broker, backorder, orderer)
    variant = line_item.variant
    needed_quantity = needed_quantity(line_item)
    solution = broker.best_offer(variant.semantic_links[0].semantic_id)

    # The number of wholesale packs we need to order to fulfill the
    # needed quantity.
    # For example, we order 2 packs of 12 cans if we need 15 cans.
    wholesale_quantity = (needed_quantity.to_f / solution.factor).ceil

    # The number of individual retail items we get with the wholesale order.
    # For example, if we order 2 packs of 12 cans, we will get 24 cans
    # and we'll account for that in our stock levels.
    retail_quantity = wholesale_quantity * solution.factor

    line = orderer.find_or_build_order_line(backorder, solution.offer)
    line.quantity = line.quantity.to_i + wholesale_quantity

    retail_quantity
  end

  # We have two different types of stock management:
  #
  # 1. on demand
  #    We don't restrict sales but account for the quantity sold in our local
  #    stock level. If it goes negative, we need more stock and trigger a
  #    backorder.
  # 2. limited stock
  #    The local stock level is a copy from another catalog. We limit sales
  #    according to that stock level. Every order reduces the local stock level
  #    and needs to trigger a backorder of the same quantity to stay in sync.
  def needed_quantity(line_item)
    variant = line_item.variant

    if variant.on_demand
      -1 * variant.on_hand # on_hand is negative and we need to replenish it.
    else
      line_item.quantity # We need to order exactly what's we sold.
    end
  end

  def load_broker(user, urls)
    FdcOfferBroker.new(user, urls)
  end

  def place_order(user, order, orderer, backorder)
    placed_order = orderer.send_order(backorder)

    return unless orderer.new?(backorder)

    delay = SALE_SESSION_DELAYS.fetch(backorder.client, 1.minute)
    wait_until = order.order_cycle.orders_close_at + delay
    CompleteBackorderJob.set(wait_until:)
      .perform_later(
        user, order.distributor, order.order_cycle, placed_order.semanticId
      )

    order.exchange.semantic_links.create!(semantic_id: placed_order.semanticId)
  end
end
