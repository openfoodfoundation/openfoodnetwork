# frozen_string_literal: true

require "system_helper"

describe "Packing Reports" do
  include AuthenticationHelper
  include WebHelper

  around do |example|
    Timecop.freeze(Time.zone.now.strftime("%Y-%m-%d 00:00")) { example.run }
  end

  let!(:open_datetime) { 1.month.ago.strftime("%Y-%m-%d 00:00") }
  let!(:close_datetime) { Time.zone.now.strftime("%Y-%m-%d 00:00") }

  describe "Packing reports" do
    before do
      login_as_admin
      visit admin_reports_path
    end

    let(:bill_address1) { create(:address, lastname: "ABRA") }
    let(:bill_address2) { create(:address, lastname: "KADABRA") }
    let(:distributor_address) {
      create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
    }
    let(:distributor) { create(:distributor_enterprise, address: distributor_address) }
    let(:order1) {
      create(:completed_order_with_totals, line_items_count: 0, distributor: distributor,
                                           bill_address: bill_address1)
    }
    let(:order2) {
      create(:completed_order_with_totals, line_items_count: 0, distributor: distributor,
                                           bill_address: bill_address2)
    }
    let(:supplier) { create(:supplier_enterprise, name: "Supplier") }
    let(:product1) { create(:simple_product, name: "Product 1", supplier: supplier ) }
    let(:variant1) { create(:variant, product: product1, unit_description: "Big") }
    let(:variant2) { create(:variant, product: product1, unit_description: "Small") }
    let(:product2) { create(:simple_product, name: "Product 2", supplier: supplier) }

    before do
      order1.finalize!
      order2.finalize!

      create(:line_item_with_shipment, variant: variant1, quantity: 1, order: order1)
      create(:line_item_with_shipment, variant: variant2, quantity: 3, order: order1)
      create(:line_item_with_shipment, variant: product2.variants.first, quantity: 3, order: order2)
    end

    describe "Pack By Customer" do
      it "displays the report" do
        click_link "Pack By Customer"

        # pre-fills with dates
        check_prefilled_dates

        click_button 'Go'

        rows = find("table.report__table").all("thead tr")
        table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
        expect(table).to eq([
                              ["Hub", "Customer Code", "First Name", "Last Name", "Supplier",
                               "Product", "Variant", "Weight", "Height", "Width", "Depth",
                               "Quantity", "TempControlled?"].map(&:upcase)
                            ])
        expect(page).to have_selector 'table.report__table tbody tr', count: 5 # Totals row/order
      end

      it "sorts alphabetically" do
        click_link "Pack By Customer"

        # pre-fills with dates
        check_prefilled_dates

        click_button 'Go'
        rows = find("table.report__table").all("tr")
        table = rows.map { |r| r.all("th,td").map { |c| c.text.strip }[3] }
        expect(table).to eq([
                              "LAST NAME",
                              order1.bill_address.lastname,
                              order1.bill_address.lastname,
                              "",
                              order2.bill_address.lastname,
                              ""
                            ])
      end
    end

    describe "Pack By Supplier" do
      it "displays the report" do
        click_link "Pack By Supplier"

        # pre-fills with dates
        check_prefilled_dates

        find(:css, "#display_summary_row").set(false) # does not include summary rows

        click_button 'Go'

        rows = find("table.report__table").all("thead tr")
        table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
        expect(table).to eq([
                              ["Hub", "Supplier", "Customer Code", "First Name", "Last Name",
                               "Product", "Variant", "Quantity", "TempControlled?"].map(&:upcase)
                            ])

        expect(all('table.report__table tbody tr').count).to eq(3) # Totals row per supplier
      end
    end
  end

  describe "With soft-deleted variants" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:oc) { create(:simple_order_cycle) }
    let(:order) {
      create(:completed_order_with_totals, line_items_count: 0,
                                           order_cycle: oc, distributor: distributor)
    }
    let(:li1) { build(:line_item_with_shipment) }
    let(:li2) { build(:line_item_with_shipment) }

    before do
      order.line_items << li1
      order.line_items << li2
      order.finalize!
      login_as_admin
    end

    describe "viewing the Pack by Product report" do
      context "when an associated variant has been soft-deleted" do
        before do
          li1.variant.delete
          visit admin_reports_path
          click_link "Pack By Product"
        end

        it "shows line items" do
          select oc.name, from: "q_order_cycle_id_in"

          # pre-fills with dates
          check_prefilled_dates

          find("button[type='submit']").click
          expect(page).to have_content li1.product.name
          expect(page).to have_content li2.product.name
        end
      end
    end
  end
end

private

def check_prefilled_dates
  expect(page).to have_input "q[order_completed_at_gt]", value: open_datetime, visible: false
  expect(page).to have_input "q[order_completed_at_lt]", value: close_datetime, visible: false
end
