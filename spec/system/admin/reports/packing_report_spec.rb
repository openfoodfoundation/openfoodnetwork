# frozen_string_literal: true

require "system_helper"

describe "Packing Reports", js: true do
  include AuthenticationHelper
  include WebHelper

  describe "Packing reports" do
    before do
      login_as_admin
      visit spree.admin_reports_path
    end

    let(:bill_address1) { create(:address, lastname: "Aman") }
    let(:bill_address2) { create(:address, lastname: "Bman") }
    let(:distributor_address) {
      create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
    }
    let(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let(:order1) { create(:order, distributor: distributor, bill_address: bill_address1) }
    let(:order2) { create(:order, distributor: distributor, bill_address: bill_address2) }
    let(:supplier) { create(:supplier_enterprise, name: "Supplier") }
    let(:product_1) { create(:simple_product, name: "Product 1", supplier: supplier ) }
    let(:variant_1) { create(:variant, product: product_1, unit_description: "Big") }
    let(:variant_2) { create(:variant, product: product_1, unit_description: "Small") }
    let(:product_2) { create(:simple_product, name: "Product 2", supplier: supplier) }

    before do
      Timecop.travel(Time.zone.local(2013, 4, 25, 14, 0, 0)) { order1.finalize! }
      Timecop.travel(Time.zone.local(2013, 4, 25, 15, 0, 0)) { order2.finalize! }

      create(:line_item_with_shipment, variant: variant_1, quantity: 1, order: order1)
      create(:line_item_with_shipment, variant: variant_2, quantity: 3, order: order1)
      create(:line_item_with_shipment, variant: product_2.master, quantity: 3, order: order2)
    end

    scenario "Pack By Customer" do
      click_link "Pack By Customer"
      fill_in 'q_completed_at_gt', with: '2013-04-25 13:00:00'
      fill_in 'q_completed_at_lt', with: '2013-04-25 16:00:00'
      # select 'Pack By Customer', from: 'report_type'
      click_button 'Search'

      rows = find("table#listing_orders").all("thead tr")
      table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
      expect(table).to eq([
                            ["Hub", "Code", "First Name", "Last Name", "Supplier",
                             "Product", "Variant", "Quantity", "TempControlled?"].map(&:upcase)
                          ])
      expect(page).to have_selector 'table#listing_orders tbody tr', count: 5 # Totals row per order
    end

    scenario "Pack By Supplier" do
      click_link "Pack By Supplier"
      fill_in 'q_completed_at_gt', with: '2013-04-25 13:00:00'
      fill_in 'q_completed_at_lt', with: '2013-04-25 16:00:00'
      # select 'Pack By Customer', from: 'report_type'
      click_button 'Search'

      rows = find("table#listing_orders").all("thead tr")
      table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
      expect(table).to eq([
                            ["Hub", "Supplier", "Code", "First Name", "Last Name",
                             "Product", "Variant", "Quantity", "TempControlled?"].map(&:upcase)
                          ])
      expect(all('table#listing_orders tbody tr').count).to eq(4) # Totals row per supplier
    end
  end

  describe "With soft-deleted variants" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle) }
    let(:order) {
      create(:order, completed_at: 1.day.ago, order_cycle: oc, distributor: distributor)
    }
    let(:li1) { build(:line_item_with_shipment) }
    let(:li2) { build(:line_item_with_shipment) }

    before do
      order.line_items << li1
      order.line_items << li2
      login_as_admin
    end

    describe "viewing a report" do
      context "when an associated variant has been soft-deleted" do
        it "shows line items" do
          li1.variant.delete

          visit spree.admin_reports_path

          click_on I18n.t("admin.reports.packing.name")
          select oc.name, from: "q_order_cycle_id_in"

          find('#q_completed_at_gt').click
          select_date(Time.zone.today - 1.day)

          find('#q_completed_at_lt').click
          select_date(Time.zone.today)

          find("button[type='submit']").click

          expect(page).to have_content li1.product.name
          expect(page).to have_content li2.product.name
        end
      end
    end
  end
end
