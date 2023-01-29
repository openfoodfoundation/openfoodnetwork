# frozen_string_literal: true

require 'system_helper'

describe "Revenues By Hub Reports" do
  include AuthenticationHelper

  let(:order) do
    create(
      :completed_order_with_totals,
      completed_at: 2.days.ago,
      order_cycle: order_cycle,
      distributor: create(:enterprise, name: "Hub 1",
                                       owner: create(:user, email: "email@email.com")),
    )
  end
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:product) { create(:product, supplier: supplier) }
  let(:supplier) { create(:supplier_enterprise) }

  before do
    create(:line_item_with_shipment, order: order, product: product)

    login_as_admin
    visit main_app.admin_report_path(report_type: 'revenues_by_hub')
  end

  context "testing report" do
    it "show the right values" do
      find("[type='submit']").click

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

      expect(page.find("table.report__table tbody tr").text).to have_content([
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
    end
  end
end
