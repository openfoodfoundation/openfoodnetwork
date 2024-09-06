# frozen_string_literal: true

# Place and update orders based on missing stock.
class FdcBackorderer
  FDC_BASE_URL = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod"
  FDC_ORDERS_URL = "#{FDC_BASE_URL}/Orders".freeze
  FDC_SALE_SESSION_URL = "#{FDC_BASE_URL}/SalesSession/#".freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def find_or_build_order(ofn_order)
    find_open_order || build_new_order(ofn_order)
  end

  def build_new_order(ofn_order)
    OrderBuilder.new_order(ofn_order, FDC_ORDERS_URL).tap do |order|
      order.saleSession = build_sale_session(ofn_order)
    end
  end

  def find_open_order
    graph = import(FDC_ORDERS_URL)
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
    DfcIo.import(result).find { |i| i.semanticType == "dfc-b:Order" }
  end

  def complete_order(semantic_id)
    backorder = import(semantic_id).find do |o|
      o.semanticType == "dfc-b:Order"
    end
    backorder.orderStatus = "dfc-v:Complete"
    send_order(backorder)
  end

  def new?(order)
    order.semanticId == FDC_ORDERS_URL
  end

  def build_sale_session(order)
    SaleSessionBuilder.build(order.order_cycle).tap do |session|
      session.semanticId = FDC_SALE_SESSION_URL
    end
  end
end
