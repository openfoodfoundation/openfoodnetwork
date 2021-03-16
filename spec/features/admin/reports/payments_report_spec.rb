# frozen_string_literal: true

require 'spec_helper'

describe "Payments Reports" do
  include AuthenticationHelper

  let!(:order) do
    create(
      :order_with_distributor,
      state: 'complete',
      completed_at: Time.zone.now,
      order_cycle: order_cycle
    )
  end
  let(:order_cycle) { create(:simple_order_cycle) }
  let!(:line_item) do
    create(:line_item_with_shipment, order: order, product: product)
  end
  let(:product) { create(:product, supplier: supplier) }
  let(:supplier) { create(:supplier_enterprise) }

  before { login_as_admin }

  it 'shows orders with payment state, their balance and totals' do
    visit spree.payments_admin_reports_path

    select I18n.t(:report_itemised_payment), from: "report_type"
    find("[type='submit']").click

    expect(page.find("#listing_orders thead tr").text).to eq([
      I18n.t(:report_header_payment_state),
      I18n.t(:report_header_distributor),
      I18n.t(:report_header_product_total_price, currency: currency_symbol),
      I18n.t(:report_header_shipping_total_price, currency: currency_symbol),
      I18n.t(:report_header_outstanding_balance_price, currency: currency_symbol),
      I18n.t(:report_header_total_price, currency: currency_symbol)
    ].join(" "))

    expect(page.find("#listing_orders tbody tr").text).to eq([
      order.payment_state,
      order.distributor.name,
      order.item_total.to_f,
      order.ship_total.to_f,
      order.outstanding_balance.to_f,
      order.total.to_f
    ].join(" "))
  end
end
