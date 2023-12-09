# frozen_string_literal: true

require 'system_helper'

describe "Revenues By Hub Reports" do
  include AuthenticationHelper

  let(:order) do
    create(
      :completed_order_with_totals,
      completed_at: 2.days.ago,
      order_cycle:,
      distributor: distributor1
    )
  end
  let(:order_with_voucher_tax_included) do
    create(
      :order_with_taxes,
      completed_at: 2.days.ago,
      order_cycle:,
      distributor: distributor2,
      product_price: 110.0,
      tax_rate_amount: 0.1,
      included_in_price: true,
      tax_rate_name: "Tax 1"
    )
  end
  let(:order_with_voucher_tax_excluded) do
    create(
      :order_with_taxes,
      completed_at: 2.days.ago,
      order_cycle:,
      distributor: distributor3,
      product_price: 110.0,
      tax_rate_amount: 0.1,
      included_in_price: true,
      tax_rate_name: "Tax 1"
    )
  end
  let(:distributor1) { create(:enterprise, name: "Hub 1", owner:) }
  let(:distributor2) { create(:enterprise, name: "Hub 2", owner:) }
  let(:distributor3) { create(:enterprise, name: "Hub 3", owner:) }
  let(:owner) { create(:user, email: 'email@email.com') }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:product) { create(:product, supplier:) }
  let(:supplier) { create(:supplier_enterprise) }

  before do
    create(:line_item_with_shipment, order:, product:)

    order_with_voucher_tax_included.create_tax_charge!
    order_with_voucher_tax_included.update_shipping_fees!
    order_with_voucher_tax_included.update_order!

    order_with_voucher_tax_excluded.create_tax_charge!
    order_with_voucher_tax_excluded.update_shipping_fees!
    order_with_voucher_tax_excluded.update_order!

    allow(VoucherAdjustmentsService).to receive(:new) do |order_arg|
      if order_arg.id == order.id
        next double(voucher_included_tax: 0.0, voucher_excluded_tax: 0.0)
      elsif order_arg.id == order_with_voucher_tax_included.id
        next double(voucher_included_tax: 0.5, voucher_excluded_tax: 0.0)
      elsif order_arg.id == order_with_voucher_tax_excluded.id
        next double(voucher_included_tax: 0.0, voucher_excluded_tax: -0.5)
      end
    end

    login_as_admin
    visit main_app.admin_report_path(report_type: 'revenues_by_hub')
  end

  context "testing report", aggregate_failures: true do
    it "show the right values" do
      run_report

      expect(page.find("table.report__table thead tr").text).to have_content([
        "HUB",
        "HUB ID",
        "HUB BUSINESS NUMBER",
        "HUB LEGAL NAME",
        "HUB CONTACT NAME",
        "HUB PUBLIC EMAIL",
        "HUB OWNER EMAIL",
        "HUB PHONE NUMBER",
        "HUB ADDRESS LINE 1",
        "HUB ADDRESS LINE 2",
        "HUB SUBURB",
        "HUB POSTCODE",
        "HUB STATE",
        "TOTAL NUMBER OF ORDERS",
        "TOTAL EXCL. TAX ($)",
        "TOTAL TAX ($)",
        "TOTAL INCL. TAX ($)"
      ].join(" "))

      lines = page.all('table.report__table tbody tr').map(&:text)
      expect(lines[0]).to have_content([
        "Hub 1",
        order.distributor.id,
        "none",
        "none",
        "none",
        "none",
        "email@email.com",
        "none",
        "10 Lovely Street",
        nil,
        "Northwest Herndon",
        "20170",
        "Victoria",
        "1",
        order.total - order.total_tax,
        order.total_tax,
        order.total
      ].compact.join(" "))

      expect(lines[1]).to have_content([
        "Hub 2",
        order_with_voucher_tax_included.distributor.id,
        "none",
        "none",
        "none",
        "none",
        "email@email.com",
        "none",
        "10 Lovely Street",
        nil,
        "Northwest Herndon",
        "20170",
        "Victoria",
        "1",
        # 160.0$ - 10.5$
        149.5,
        # 10$ tax + 0.5$ voucher_included_tax
        10.5,
        # 5 line_items at 10$ each + 1 line_item at 110$
        160.0
      ].compact.join(" "))

      expect(lines[2]).to have_content([
        "Hub 3",
        order_with_voucher_tax_excluded.distributor.id,
        "none",
        "none",
        "none",
        "none",
        "email@email.com",
        "none",
        "10 Lovely Street",
        nil,
        "Northwest Herndon",
        "20170",
        "Victoria",
        "1",
        # 160.0$ - 9.5$
        150.5,
        # 10$ tax - 0.5$ voucher_excluded_tax
        9.5,
        # 5 line_items at 10$ each + 1 line_item at 110$
        160.0
      ].compact.join(" "))
    end
  end
end
