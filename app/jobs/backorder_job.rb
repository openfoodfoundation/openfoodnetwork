# frozen_string_literal: true

class BackorderJob < ApplicationJob
  FDC_BASE_URL =  "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod"
  FDC_CATALOG_URL = "#{FDC_BASE_URL}/SuppliedProducts".freeze
  FDC_ORDERS_URL = "#{FDC_BASE_URL}/Orders".freeze
  FDC_SALE_SESSION_URL = "#{FDC_BASE_URL}/SalesSession/#".freeze

  # The FDC implementation needs special ids for new objects:
  FDC_NEW_ORDER_URL = "#{FDC_ORDERS_URL}/#".freeze
  FDC_ORDER_LINES_URL = "#{FDC_ORDERS_URL}/#/OrderLines".freeze

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
    backorder = build_order(order)
    catalog = load_catalog(order.distributor.owner)

    linked_variants.each_with_index do |variant, index|
      needed_quantity = -1 * variant.on_hand
      offer = best_offer(catalog, variant)

      # Order lines are enumerated in the FDC API:
      line = build_order_line(offer, needed_quantity)
      line.semanticId = "#{FDC_ORDER_LINES_URL}/#{index}"
      backorder.lines << line
    end

    lines = backorder.lines
    offers = lines.map(&:offer)
    products = offers.map(&:offeredItem)
    session = build_sale_session(order)
    json = DfcIo.export(backorder, *lines, *offers, *products, session)

    api = DfcRequest.new(order.distributor.owner)

    # Create order via POST:
    api.call(FDC_ORDERS_URL, json)

    # Once we have transformations and know the quantities in bulk products
    # we will need to increase on_hand by the ordered quantity.
    linked_variants.each do |variant|
      variant.on_hand = 0
    end
  end

  # This needs to find an existing order when the API is available.
  def self.build_order(ofn_order)
    OrderBuilder.new_order(ofn_order, FDC_NEW_ORDER_URL)
  end

  def self.build_order_line(offer, quantity)
    OrderLineBuilder.build(offer, quantity)
  end

  def self.build_sale_session(order)
    SaleSessionBuilder.build(order.order_cycle).tap do |session|
      session.semanticId = FDC_SALE_SESSION_URL
    end
  end

  def self.best_offer(catalog, variant)
    link = variant.semantic_links[0]

    return unless link

    product = catalog.find { |item| item.semanticId == link.semantic_id }
    offer_of(product)
  end

  def self.offer_of(product)
    product&.catalogItems&.first&.offers&.first&.tap do |offer|
      # Unfortunately, the imported catalog doesn't provide the reverse link:
      offer.offeredItem = product
    end
  end

  def self.load_catalog(user)
    api = DfcRequest.new(user)
    catalog_json = api.call(FDC_CATALOG_URL)
    DfcIo.import(catalog_json)
  end

  def perform(*args)
    # The ordering logic will live here later.
  end
end
