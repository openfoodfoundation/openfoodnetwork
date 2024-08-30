# frozen_string_literal: true

# Place and update orders based on missing stock.
class FdcBackorderer
  FDC_BASE_URL = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod"
  FDC_ORDERS_URL = "#{FDC_BASE_URL}/Orders".freeze
  FDC_NEW_ORDER_URL = "#{FDC_ORDERS_URL}/#".freeze

  def find_or_build_order(ofn_order)
    remote_order = find_open_order(ofn_order.distributor.owner)
    remote_order || OrderBuilder.new_order(ofn_order, FDC_NEW_ORDER_URL)
  end

  def find_open_order(user)
    graph = import(user, FDC_ORDERS_URL)
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

  def import(user, url)
    api = DfcRequest.new(user)
    json = api.call(url)
    DfcIo.import(json)
  end

  def send_order(ofn_order, backorder)
    lines = backorder.lines
    offers = lines.map(&:offer)
    products = offers.map(&:offeredItem)
    session = build_sale_session(ofn_order)
    json = DfcIo.export(backorder, *lines, *offers, *products, session)

    api = DfcRequest.new(ofn_order.distributor.owner)

    if backorder.semanticId == FDC_NEW_ORDER_URL
      # Create order via POST:
      api.call(FDC_ORDERS_URL, json)
    else
      # Update existing:
      api.call(backorder.semanticId, json)
    end
  end
end
