# frozen_string_literal: true

# The DFC standard doesn't include endpoint discovery yet.
# So for now we are guessing URLs based on our FDC pilot project.
class FdcUrlBuilder
  attr_reader :catalog_url, :orders_url, :sale_session_url

  # At the moment, we start with a product link like this:
  #
  # https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635
  def initialize(semantic_id)
    @catalog_url, _slash, _id = semantic_id.rpartition("/")
    @orders_url = @catalog_url.sub("/SuppliedProducts", "/Orders")
    @sale_session_url = @catalog_url.sub("/SuppliedProducts", "/SalesSession/#")
  end
end
