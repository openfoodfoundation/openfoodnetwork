# frozen_string_literal: true

require "system_helper"

RSpec.describe "Orders And Distributors" do
  include AuthenticationHelper
  include WebHelper

  describe "Orders And Distributors" do
    let!(:distributor_enterprise1) { create(:distributor_enterprise) }
    let!(:distributor_enterprise2) { create(:distributor_enterprise) }
    let!(:ready_to_ship_order1) {
      create(:order_ready_to_ship, distributor_id: distributor_enterprise1.id)
    }
    let!(:ready_to_ship_order2) {
      create(:order_ready_to_ship, distributor_id: distributor_enterprise2.id)
    }

    before do
      login_as(distributor_enterprise1.owner)
      visit admin_reports_path
      click_link "Orders And Distributors"
    end

    it "generates the report" do
      run_report

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
          order_id: ready_to_ship_order1.id # Total rows should equal nr. of line items, per order
        ).count
      )

      # displays only orders from the hub it is managing
      expect(page).to have_content(distributor_enterprise1.name), count: 5
      expect(page).to_not have_content(distributor_enterprise2.name)
    end
  end
end
