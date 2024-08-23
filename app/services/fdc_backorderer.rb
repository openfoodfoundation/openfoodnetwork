# frozen_string_literal: true

# Place and update orders based on missing stock.
class FdcBackorderer
  FDC_BASE_URL = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod"
  FDC_ORDERS_URL = "#{FDC_BASE_URL}/Orders".freeze
  FDC_NEW_ORDER_URL = "#{FDC_ORDERS_URL}/#".freeze

  def find_or_build_order(ofn_order)
    OrderBuilder.new_order(ofn_order, FDC_NEW_ORDER_URL)
  end
end
