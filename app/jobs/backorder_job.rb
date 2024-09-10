# frozen_string_literal: true

class BackorderJob < ApplicationJob
  FDC_BASE_URL =  "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod"
  FDC_CATALOG_URL = "#{FDC_BASE_URL}/SuppliedProducts".freeze
  FDC_ORDERS_URL = "#{FDC_BASE_URL}/Orders".freeze

  # In the current FDC project, the shop wants to review and adjust orders
  # before finalising. They also run a market stall and need to adjust stock
  # levels after the market. This should be done within four hours.
  SALE_SESSION_DELAY = 4.hours

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

    return if linked_variants.empty?

    # At this point we want to move to the background with perform_later.
    # But while this is in development I'll perform the backordering
    # immediately. It should ease debugging for now.
    place_backorder(order, linked_variants)
  end

  def self.place_backorder(order, linked_variants)
    user = order.distributor.owner
    orderer = FdcBackorderer.new(user)
    backorder = orderer.find_or_build_order(order)
    broker = load_broker(order.distributor.owner)

    linked_variants.each do |variant|
      needed_quantity = -1 * variant.on_hand
      offer = broker.best_offer(variant.semantic_links[0].semantic_id)

      line = orderer.find_or_build_order_line(backorder, offer)
      line.quantity = line.quantity.to_i + needed_quantity
    end

    placed_order = orderer.send_order(backorder)

    schedule_order_completion(user, order, placed_order) if orderer.new?(backorder)

    # Once we have transformations and know the quantities in bulk products
    # we will need to increase on_hand by the ordered quantity.
    linked_variants.each do |variant|
      variant.on_hand = 0
    end
  end

  def self.load_broker(user)
    FdcOfferBroker.new(load_catalog(user))
  end

  def self.load_catalog(user)
    api = DfcRequest.new(user)
    catalog_json = api.call(FDC_CATALOG_URL)
    DfcIo.import(catalog_json)
  end

  def self.schedule_order_completion(user, order, placed_order)
    wait_until = order.order_cycle.orders_close_at + SALE_SESSION_DELAY
    CompleteBackorderJob.set(wait_until:)
      .perform_later(user, placed_order.semanticId)
  end

  def perform(*args)
    # The ordering logic will live here later.
  end
end
