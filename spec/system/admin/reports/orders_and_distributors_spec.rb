# frozen_string_literal: true

require "system_helper"

RSpec.describe "Orders And Distributors" do
  include AuthenticationHelper
  include WebHelper
  include ReportsHelper

  describe "Orders And Distributors" do
    let!(:report_url) { admin_report_path(report_type: :orders_and_distributors) }
    let!(:distributor) { create(:distributor_enterprise, name: "By Bike") }
    let!(:distributor2) { create(:distributor_enterprise, name: "By Moto") }
    let!(:completed_at) { Time.zone.now.to_fs(:db) }

    around do |example|
      Timecop.travel(completed_at) { example.run }
    end

    let!(:order) {
      create(:order_ready_to_ship, distributor_id: distributor.id, completed_at:)
    }
    let!(:order2) {
      create(:order_ready_to_ship, distributor_id: distributor2.id, completed_at:)
    }

    context "as an enterprise user" do
      let(:header) {
        ["Order date", "Order Id", "Customer Name", "Customer Email", "Customer Phone",
         "Customer City", "SKU", "Product", "Variant", "Quantity", "Max Quantity",
         "Cost", "Shipping Cost", "Payment Method", "Distributor", "Distributor address",
         "Distributor city", "Distributor postcode", "Shipping Method",
         "Shipping instructions"]
      }
      let(:line_item1) {
        [completed_at, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item2) {
        [completed_at, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item3) {
        [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item4) {
        [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item5) {
        [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }

      before do
        login_as(distributor.owner)
        visit report_url
        run_report
      end

      it "generates the report" do
        expect(table_headers).to eq([header])

        # Total rows should equal nr. of line items, per order
        expect(all('table.report__table tbody tr').count).to eq(5)

        # displays only orders from the hub it is managing
        within ".report__table" do
          expect(page).to have_content(distributor.name, count: 5)
        end

        # only sees line items from orders it manages
        expect(page).not_to have_content(distributor2.name)

        # displayes table contents correctly, per line item
        table = page.find("table.report__table tbody")
        expect(table).to have_content(line_item1)
        expect(table).to have_content(line_item2)
        expect(table).to have_content(line_item3)
        expect(table).to have_content(line_item4)
        expect(table).to have_content(line_item5)
      end

      describe "downloading the report" do
        shared_examples "reports generated as" do |output_type, extension|
          context output_type.to_s do
            it "downloads the #{output_type} file" do
              select output_type, from: "report_format"

              expect { generate_report }.to change { downloaded_filenames.length }.from(0).to(1)

              expect(downloaded_filename).to match(/.*\.#{extension}/)

              downloaded_file_txt = load_file_txt(extension, downloaded_filename)

              expect(downloaded_file_txt).to have_text header.join(" ")
              expect(downloaded_file_txt).to have_text(
                "By Bike 10 Lovely Street Herndon 20170 UPS Ground", count: 5
              )
            end
          end
        end

        it_behaves_like "reports generated as", "CSV", "csv"
        it_behaves_like "reports generated as", "Spreadsheet", "xlsx"
      end
    end

    context "as admin" do
      before do
        login_as_admin
        visit report_url
        run_report
      end

      context "with two orders on the same day at different times" do
        let(:completed_at1) { 1500.hours.ago } # 1500 hours in the past
        let(:completed_at2) { 1700.hours.ago } # 1700 hours in the past
        let(:datetime_start1) { 1600.hours.ago } # 1600 hours in the past
        let(:datetime_start2) { 1800.hours.ago } # 1600 hours in the past
        let(:datetime_end) { 1400.hours.ago } # 1400 hours in the past
        let!(:order3) {
          create(:order_ready_to_ship, distributor_id: distributor.id, completed_at: completed_at1)
        }
        let!(:order4) {
          create(:order_ready_to_ship, distributor_id: distributor.id, completed_at: completed_at2)
        }

        context "applying time/date filters" do
          it "is precise to time of day, not just date" do
            # When I generate a customer report
            # with a timeframe that includes one order but not the other
            find("input.datepicker").click
            select_dates_from_daterangepicker datetime_start1, datetime_end
            find(".shortcut-buttons-flatpickr-button").click # closes flatpickr

            run_report
            # Then I should see the rows for the first order but not the second
            # One row per line item - order3 only
            within ".report__table" do
              expect(page).to have_content(distributor.name, count: 5)
            end
            expect(page).to have_text(order3.email, count: 5)

            # setting a time interval to include both orders
            find("input.datepicker").click
            select_dates_from_daterangepicker datetime_start2, Time.zone.now

            run_report
            # Then I should see the both orders
            within ".report__table" do
              expect(page).to have_content(distributor.name, count: 10)
            end
            expect(page).to have_text(order3.email, count: 5)
            expect(page).to have_text(order4.email, count: 5)
          end
        end

        context "applying distributor filters" do
          it "displays line items from the correct distributors" do
            # for one distributor
            select2_select distributor.name, from: "q_distributor_id_in"
            run_report

            within ".report__table" do
              expect(page).to have_content(distributor.name, count: 15)
            end
            clear_select2("#s2id_q_distributor_id_in")

            # for another distributor
            select2_select distributor2.name, from: "q_distributor_id_in"
            run_report

            within ".report__table" do
              expect(page).to have_content(distributor2.name, count: 5)
            end
          end
        end
      end
    end
  end
end
