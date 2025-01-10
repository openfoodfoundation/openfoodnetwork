# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Revenues By Hub Reports" do
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
      product_price: 110,
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
      included_in_price: false,
      tax_rate_name: "Tax 1"
    )
  end
  let(:distributor1) { create(:enterprise, name: "Hub 1", owner:, external_billing_id: 'INV1234') }
  let(:distributor2) { create(:enterprise, name: "Hub 2", owner:) }
  let(:distributor3) { create(:enterprise, name: "Hub 3", owner:, external_billing_id: 'INV4321') }
  let(:owner) { create(:user, email: 'email@email.com') }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:product) { create(:product) }
  let(:voucher2) { create(:voucher_flat_rate, code: 'code', enterprise: distributor2, amount: 10) }
  let(:voucher3) { create(:voucher_flat_rate, code: 'code', enterprise: distributor3, amount: 10) }

  before do
    create(:line_item_with_shipment, order:, product:)

    apply_voucher(order_with_voucher_tax_included, voucher2)
    apply_voucher(order_with_voucher_tax_excluded, voucher3)

    login_as_admin
    visit main_app.admin_report_path(report_type: 'revenues_by_hub')
  end

  context "testing report", aggregate_failures: true do
    it "show the right values" do
      run_report

      expect(page.find("table.report__table thead tr").text).to have_content([
        "Hub",
        "Hub ID",
        "Hub Business Number",
        "Hub External Billing Id",
        "Hub Legal Name",
        "Hub Contact Name",
        "Hub Public Email",
        "Hub Owner Email",
        "Hub Phone Number",
        "Hub Address Line 1",
        "Hub Address Line 2",
        "Hub Suburb",
        "Hub Postcode",
        "Hub State",
        "Total Number of Orders",
        "Total excl. tax ($)",
        "Total Tax ($)",
        "Total incl. tax ($)"
      ].join(" "))

      lines = page.all('table.report__table tbody tr').map(&:text)
      first_line = lines.detect { |line| line.include?('Hub 1') }
      expect(first_line).to have_content([
        "Hub 1",
        order.distributor.id,
        "none",
        "INV1234",
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

      second_line = lines.detect { |line| line.include?('Hub 2') }
      expect(second_line).to have_content([
        "Hub 2",
        order_with_voucher_tax_included.distributor.id,
        "none",
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
        140.63,
        9.37,
        150.0
      ].compact.join(" "))

      third_line = lines.detect { |line| line.include?('Hub 3') }
      expect(third_line).to have_content([
        "Hub 3",
        order_with_voucher_tax_excluded.distributor.id,
        "none",
        "INV4321",
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
        150.64,
        10.36,
        161.0
      ].compact.join(" "))
    end
  end

  def apply_voucher(order, voucher)
    voucher.create_adjustment(voucher.code, order)

    # Update taxes
    order.create_tax_charge!
    order.update_shipping_fees!
    order.update_order!

    OrderManagement::Order::Updater.new(order).update_voucher
  end
end
