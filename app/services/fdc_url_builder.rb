# frozen_string_literal: true

# The DFC standard doesn't include endpoint discovery yet.
# So for now we are guessing URLs based on our FDC pilot project.
class FdcUrlBuilder
  attr_reader :catalog_url, :orders_url, :sale_session_url

  # Known product link formats:
  # * https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635
  # * http://test.host/api/dfc/enterprises/10000/supplied_products/10001 (OFN)
  def initialize(semantic_id)
    base_url, _slash, _id = semantic_id.rpartition("/")
    @catalog_url = base_url.sub("/supplied_products", "/catalog_items")
    @orders_url = base_url.sub("/SuppliedProducts", "/Orders")
      .sub("/supplied_products", "/orders")
    @sale_session_url = base_url.sub("/SuppliedProducts", "/SalesSession/#")
  end
end
