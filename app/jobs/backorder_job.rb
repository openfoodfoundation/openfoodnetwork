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

  def self.check_stock(order)
    variants_needing_stock = order.variants.select do |variant|
      # TODO: scope variants to hub.
      # We are only supporting producer stock at the moment.
      variant.on_hand&.negative?
    end

    linked_variants = variants_needing_stock.select do |variant|
      variant.semantic_links.present?
    end

    perform_later(order, linked_variants) if linked_variants.present?
  rescue StandardError => e
    # Errors here shouldn't affect the checkout. So let's report them
    # separately:
    Bugsnag.notify(e) do |payload|
      payload.add_metadata(:order, order)
    end
  end

  def perform(order, linked_variants)
    OrderLocker.lock_order_and_variants(order) do
      place_backorder(order, linked_variants)
    end
  rescue StandardError => e
    # If the backordering fails, we need to tell the shop owner because they
    # need to organgise more stock.
    Bugsnag.notify(e) do |payload|
      payload.add_metadata(:order, order)
      payload.add_metadata(:linked_variants, linked_variants)
    end
  end

  def place_backorder(order, linked_variants)
    user = order.distributor.owner

    # We are assuming that all variants are linked to the same wholesale
    # shop and its catalog:
    urls = FdcUrlBuilder.new(linked_variants[0].semantic_links[0].semantic_id)
    orderer = FdcBackorderer.new(user, urls)

    backorder = orderer.find_or_build_order(order)
    broker = load_broker(order.distributor.owner, urls)
    ordered_quantities = {}

    linked_variants.each do |variant|
      retail_quantity = add_item_to_backorder(variant, broker, backorder, orderer)
      ordered_quantities[variant] = retail_quantity
    end

    place_order(user, order, orderer, backorder)

    linked_variants.each do |variant|
      variant.on_hand += ordered_quantities[variant]
    end
  end

  def add_item_to_backorder(variant, broker, backorder, orderer)
    needed_quantity = -1 * variant.on_hand
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
  end
end
