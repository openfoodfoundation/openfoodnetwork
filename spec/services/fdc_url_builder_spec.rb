# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FdcUrlBuilder do
  subject(:urls) { FdcUrlBuilder.new(product_link) }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }

  it "knows the right URLs" do
    expect(subject.catalog_url).to eq "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
    expect(subject.orders_url).to eq "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/Orders"
    expect(subject.sale_session_url).to eq "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SalesSession/#"
  end

  context "OFN URLs" do
    let(:product_link) {
      "http://test.host/api/dfc/enterprises/10000/supplied_products/10001"
    }

    it "knows the right URLs" do
      expect(subject.catalog_url).to eq "http://test.host/api/dfc/enterprises/10000/supplied_products" # but shouldn't it be catalog_items?
      expect(subject.orders_url).to eq "http://test.host/api/dfc/enterprises/10000/orders"
      # expect(subject.sale_session_url).to eq "" # not yet implemented
    end
  end
end
