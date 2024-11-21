# frozen_string_literal: true

# Place and update orders based on missing stock.
class FdcBackorderer
  attr_reader :user, :urls

  def initialize(user, urls)
    @user = user
    @urls = urls
  end

  def find_or_build_order(ofn_order)
    find_open_order(ofn_order) || build_new_order(ofn_order)
  end

  def build_new_order(ofn_order)
    OrderBuilder.new_order(ofn_order, urls.orders_url).tap do |order|
      order.saleSession = build_sale_session(ofn_order)
    end
  end

  # Try the new method and fall back to old method.
  def find_open_order(ofn_order)
    lookup_open_order(ofn_order) || find_last_open_order
  end

  def lookup_open_order(ofn_order)
    # There should be only one link at the moment but we may support
    # ordering from multiple suppliers one day.
    semantic_ids = ofn_order.semantic_links.pluck(:semantic_id)

    semantic_ids.lazy
      # Make sure we select an order from the right supplier:
      .select { |id| id.starts_with?(urls.orders_url) }
      # Fetch the order from the remote DFC server, lazily:
      .map { |id| find_order(id) }
      .compact
      # Just in case someone completed the order without updating our database:
      .select { |o| o.orderStatus[:path] == "Held" }
      .first
      # The DFC Connector doesn't recognise status values properly yet.
      # So we are overriding the value with something that can be exported.
      &.tap { |o| o.orderStatus = "dfc-v:Held" }
  end

  # DEPRECATED
  #
  # We now store links to orders we placed. So we don't need to search
  # through all orders and pick a random open one.
  # But for compatibility with currently open order cycles that don't have
  # a stored link yet, we keep this method as well.
  def find_last_open_order
    graph = import(urls.orders_url)
    open_orders = graph&.select do |o|
      o.semanticType == "dfc-b:Order" && o.orderStatus[:path] == "Held"
    end

    return if open_orders.blank?

    # If there are multiple open orders, we don't know which one to choose.
    # We want the order we placed for the same distributor in the same order
    # cycle before. So here are some assumptions for this to work:
    #
    # * We see only orders for our distributor. The endpoint URL contains the
    #   the distributor name and is currently hardcoded.
    # * There's only one open order cycle at a time. Otherwise we may select
    #   an order of an old order cycle.
    # * Orders are finalised when the order cycle closes. So _Held_ orders
    #   always belong to an open order cycle.
    # * We see only our own orders. This assumption is wrong. The Shopify
    #   integration places held orders as well and they are visible to us.
    #
    # Unfortunately, the endpoint doesn't tell who placed the order.
    # TODO: We need to remember the link to the order locally.
    # Or the API is updated to include the orderer.
    #
    # For now, we just guess:
    open_orders.last.tap do |order|
      # The DFC Connector doesn't recognise status values properly yet.
      # So we are overriding the value with something that can be exported.
      order.orderStatus = "dfc-v:Held"
    end
  end

  def find_order(semantic_id)
    find_subject(import(semantic_id), "dfc-b:Order")
  end

  def find_or_build_order_line(order, offer)
    find_order_line(order, offer) || build_order_line(order, offer)
  end

  def build_order_line(order, offer)
    # Order lines are enumerated in the FDC API and we must assign a unique
    # semantic id. We need to look at current ids to avoid collisions.
    # existing_ids = order.lines.map do |line|
    #   line.semanticId.match(/[0-9]+$/).to_s.to_i
    # end
    # next_id = existing_ids.max.to_i + 1

    # Suggested by FDC team:
    next_id = order.lines.count + 1

    OrderLineBuilder.build(offer, 0).tap do |line|
      line.semanticId = "#{order.semanticId}/OrderLines/#{next_id}"
      order.lines << line
    end
  end

  def find_order_line(order, offer)
    order.lines.find do |line|
      line.offer.offeredItem.semanticId == offer.offeredItem.semanticId
    end
  end

  def find_subject(object_or_graph, type)
    if object_or_graph.is_a?(Array)
      object_or_graph.find { |i| i.semanticType == type }
    else
      object_or_graph
    end
  end

  def import(url)
    api = DfcRequest.new(user)
    json = api.call(url)
    DfcIo.import(json)
  end

  def send_order(backorder)
    lines = backorder.lines
    offers = lines.map(&:offer)
    products = offers.map(&:offeredItem)
    sessions = [backorder.saleSession].compact
    json = DfcIo.export(backorder, *lines, *offers, *products, *sessions)

    api = DfcRequest.new(user)

    method = if new?(backorder)
               :post # -> create
             else
               :put  # -> update
             end

    result = api.call(backorder.semanticId, json, method:)
    find_subject(DfcIo.import(result), "dfc-b:Order")
  end

  def complete_order(backorder)
    backorder.orderStatus = "dfc-v:Complete"
    send_order(backorder)
  end

  def new?(order)
    order.semanticId == urls.orders_url
  end

  def build_sale_session(order)
    SaleSessionBuilder.build(order.order_cycle).tap do |session|
      session.semanticId = urls.sale_session_url
    end
  end
end
