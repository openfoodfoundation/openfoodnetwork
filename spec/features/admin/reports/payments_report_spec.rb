# frozen_string_literal: true

require 'spec_helper'

describe "Payments Reports" do
  include AuthenticationHelper

  let(:order) do
    create(
      :order_with_distributor,
      state: 'complete',
      completed_at: Time.zone.now,
      order_cycle: order_cycle
    )
  end
  let(:other_order) do
    create(
      :order_with_distributor,
      state: 'complete',
      completed_at: Time.zone.now,
      order_cycle: order_cycle,
      distributor: order.distributor
    )
  end
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:product) { create(:product, supplier: supplier) }
  let(:supplier) { create(:supplier_enterprise) }

  before do
    create(:line_item_with_shipment, order: order, product: product)
    create(:line_item_with_shipment, order: other_order, product: product)

    login_as_admin
  end

  context "when choosing itemised payments report type" do
    it "shows orders with payment state, their balance and totals" do
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
        order.item_total.to_f + other_order.item_total.to_f,
        order.ship_total.to_f + other_order.ship_total.to_f,
        order.outstanding_balance.to_f + other_order.outstanding_balance.to_f,
        order.total.to_f + other_order.total.to_f
      ].compact.join(" "))
    end
  end

  context 'when choosing payment totals report type' do
    let(:paypal) { create(:payment_method, name: "PayPal") }
    let!(:paypal_payment) { create(:payment, order: order, payment_method: paypal, state: "completed", amount: 5) }

    let(:eft) { create(:payment_method, name: "EFT") }
    let!(:eft_payment) { create(:payment, order: other_order, payment_method: eft, state: "completed", amount: 6) }

    it 'shows orders with payment state, their balance and and payment totals' do
      visit spree.payments_admin_reports_path

      select I18n.t(:report_payment_totals), from: "report_type"
      find("[type='submit']").click

      expect(page.find("#listing_orders thead tr").text).to eq([
        I18n.t(:report_header_payment_state),
        I18n.t(:report_header_distributor),
        I18n.t(:report_header_product_total_price, currency: currency_symbol),
        I18n.t(:report_header_shipping_total_price, currency: currency_symbol),
        I18n.t(:report_header_total_price, currency: currency_symbol),
        I18n.t(:report_header_eft_price, currency: currency_symbol),
        I18n.t(:report_header_paypal_price, currency: currency_symbol),
        I18n.t(:report_header_outstanding_balance_price, currency: currency_symbol),
      ].join(" "))

      expect(page.find("#listing_orders tbody tr").text).to eq([
        order.payment_state,
        order.distributor.name,
        order.item_total.to_f + other_order.item_total.to_f,
        order.ship_total.to_f + other_order.ship_total.to_f,
        order.total.to_f + other_order.total.to_f,
        eft_payment.amount.to_f,
        paypal_payment.amount.to_f,
        order.outstanding_balance.to_f + other_order.outstanding_balance.to_f,
      ].join(" "))
    end
  end
end
