# frozen_string_literal: true

require "system_helper"

RSpec.describe "Orders And Distributors" do
  include AuthenticationHelper
  include WebHelper

  describe "Orders And Distributors" do
    let!(:distributor) { create(:distributor_enterprise, name: "By Bike") }
    let!(:distributor2) { create(:distributor_enterprise, name: "By Moto") }
    let!(:completed_at) { Time.zone.now.to_fs(:db) }

    let!(:order) {
      create(:order_ready_to_ship, distributor_id: distributor.id, completed_at:)
    }
    let!(:order2) {
      create(:order_ready_to_ship, distributor_id: distributor2.id, completed_at:)
    }

    let(:line_item1) {
      [completed_at, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
       "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check", "By Bike",
       "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
    }
    let(:line_item2) {
      [completed_at, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
       "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check", "By Bike",
       "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
    }
    let(:line_item3) {
      [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
       "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check", "By Bike",
       "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
    }
    let(:line_item4) {
      [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
       "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check", "By Bike",
       "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
    }
    let(:line_item5) {
      [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
       "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check", "By Bike",
       "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
    }

    before do
      login_as(distributor.owner)
      visit admin_reports_path
      click_link "Orders And Distributors"
      run_report
    end

    it "generates the report" do
      rows = find("table.report__table").all("thead tr")
      table_headers = rows.map { |r| r.all("th").map { |c| c.text.strip } }

      expect(table_headers).to eq([
                                    ['Order date',
                                     'Order Id',
                                     'Customer Name',
                                     'Customer Email',
                                     'Customer Phone',
                                     'Customer City',
                                     'SKU',
                                     'Item name',
                                     'Variant',
                                     'Quantity',
                                     'Max Quantity',
                                     'Cost',
                                     'Shipping Cost',
                                     'Payment Method',
                                     'Distributor',
                                     'Distributor address',
                                     'Distributor city',
                                     'Distributor postcode',
                                     'Shipping Method',
                                     'Shipping instructions']
                                  ])

      expect(all('table.report__table tbody tr').count).to eq(
        Spree::LineItem.where(
          order_id: order.id # Total rows should equal nr. of line items, per order
        ).count
      )

      # displays only orders from the hub it is managing
      expect(page).to have_content(distributor.name), count: 5
      expect(page).not_to have_content(distributor2.name)

      # displayes table contents correctly, per line item
      table = page.find("table.report__table tbody")
      expect(table).to have_content(line_item1)
      expect(table).to have_content(line_item2)
      expect(table).to have_content(line_item3)
      expect(table).to have_content(line_item4)
      expect(table).to have_content(line_item5)
    end
  end
end
