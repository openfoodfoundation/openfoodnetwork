# frozen_string_literal: true

require "system_helper"

RSpec.describe "Orders And Fulfillment" do
  include AuthenticationHelper
  include WebHelper

  describe "reports" do
    let(:current_user) { create(:admin_user) }

    before do
      login_as(current_user)
      visit admin_reports_path
    end

    let(:bill_address1) { create(:address, firstname: "Dont", lastname: " Worry") }
    let(:bill_address2) { create(:address, firstname: "Chamois", lastname: "xaxa") }
    let(:distributor_address) {
      create(:address, address1: "distributor address", city: 'The Shire', zipcode: "1234")
    }
    let(:distributor) {
      create(:distributor_enterprise,
             with_payment_and_shipping: true,
             address: distributor_address,
             name: "Distributor Name")
    }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:order1) {
      create(:completed_order_with_totals, line_items_count: 0, distributor:,
                                           bill_address: bill_address1,
                                           order_cycle_id: order_cycle.id)
    }
    let(:order2) {
      create(:completed_order_with_totals, line_items_count: 0, distributor:,
                                           bill_address: bill_address2,
                                           order_cycle_id: order_cycle.id)
    }
    let(:supplier) { create(:supplier_enterprise, name: "Supplier Name") }
    let(:product) { create(:simple_product, name: "Baked Beans", supplier_id: supplier.id ) }
    let(:variant1) { create(:variant, product:, unit_description: "Big", supplier:) }
    let(:variant2) { create(:variant, product:, unit_description: "Small", supplier: ) }

    before do
      # order1 has two line items / variants
      create(:line_item_with_shipment, variant: variant1, quantity: 1, order: order1)
      create(:line_item_with_shipment, variant: variant2, quantity: 3, order: order1)
      # order2 has one line items / variants
      create(:line_item_with_shipment, variant: variant1, quantity: 2, order: order2)
    end

    describe "Order Cycle Customer Totals" do
      before do
        click_link "Order Cycle Customer Totals"
      end

      it "displays the report" do
        run_report

        rows = find("table.report__table").all("thead tr")
        table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
        expect(table).to eq([
                              ["Hub",
                               "Customer",
                               "Email",
                               "Phone",
                               "Producer",
                               "Product",
                               "Variant",
                               "Quantity",
                               "Item ($)",
                               "Item + Fees ($)",
                               "Admin & Handling ($)",
                               "Ship ($)",
                               "Pay fee ($)",
                               "Total ($)",
                               "Paid?",
                               "Shipping",
                               "Delivery?",
                               "Ship Street",
                               "Ship Street 2",
                               "Ship City",
                               "Ship Postcode",
                               "Ship State",
                               "Comments",
                               "SKU",
                               "Order Cycle",
                               "Payment Method",
                               "Customer Code",
                               "Tags",
                               "Billing Street",
                               "Billing Street 2",
                               "Billing City",
                               "Billing Postcode",
                               "Billing State",
                               "Order number",
                               "Date"]
                            ])
      end

      context "order cycles with nil opening or closing times" do
        before do
          order_cycle.update!(orders_open_at: Time.zone.now, orders_close_at: nil,
                              name: "My Order Cycle")
        end

        it "correclty renders the report" do
          run_report
          expect(page).to have_content "My Order Cycle"
        end
      end

      context "with two orders on the same day at different times" do
        let(:completed_at1) { 1500.hours.ago } # 1500 hours in the past
        let(:completed_at2) { 1700.hours.ago } # 1700 hours in the past
        let(:datetime_start1) { 1600.hours.ago } # 1600 hours in the past
        let(:datetime_start2) { 1800.hours.ago } # 1600 hours in the past
        let(:datetime_end) { 1400.hours.ago } # 1400 hours in the past

        before do
          travel_to(completed_at1) { order1.finalize! }
          travel_to(completed_at2) { order2.finalize! }
        end

        it "is precise to time of day, not just date" do
          # When I generate a customer report
          # with a timeframe that includes one order but not the other
          find("input.datepicker").click
          select_dates_from_daterangepicker datetime_start1, datetime_end
          find(".shortcut-buttons-flatpickr-button").click # closes flatpickr

          find("#display_summary_row").set(false) # hides the summary rows
          run_report
          # Then I should see the rows for the first order but not the second
          # One row per line item - order1 only
          expect(all('table.report__table tbody tr').count).to eq(2)

          find("#display_summary_row").set(true) # displays the summary rows
          run_report
          # Then I should see the rows for the first order but not the second
          expect(all('table.report__table tbody tr').count).to eq(3)
          # 2 rows for order1 + 1 summary row

          # setting a time interval to include both orders
          find("input.datepicker").click
          select_dates_from_daterangepicker datetime_start2, Time.zone.now
          run_report
          # Then I should see the rows for both orders
          expect(all('table.report__table tbody tr').count).to eq(5)
          # 2 rows for order1 + 1 summary row
          # 1 row for order2 + 1 summary row
        end
      end

      context "with different customers name" do
        let(:bill_address3) { create(:address, firstname: "bou", lastname: "yaka") }
        let(:bill_address4) { create(:address, firstname: "Ave", lastname: "Zebu") }
        let(:order3) {
          create(:completed_order_with_totals, line_items_count: 0,
                                               distributor:,
                                               bill_address: bill_address3)
        }
        let(:order4) {
          create(:completed_order_with_totals, line_items_count: 0,
                                               distributor:,
                                               bill_address: bill_address4)
        }

        before do
          create(:line_item_with_shipment, variant: variant2, quantity: 1, order: order3)
          create(:line_item_with_shipment, variant: variant2, quantity: 1, order: order4)
        end

        it "orders the report by customer name, case insensitive" do
          run_report
          rows = find("table.report__table tbody").all("tr.summary-row")
          expect(rows[0]).to have_content "Dont Worry"
          expect(rows[1]).to have_content "Chamois xaxa"
          expect(rows[2]).to have_content "bou yaka"
          expect(rows[3]).to have_content "Ave Zebu"
        end
      end

      context "When filtering by product" do
        let(:variant1) { create(:variant, product:, unit_description: "Big") }
        let(:variant3) { create(:variant) }

        before do
          create(:line_item_with_shipment, variant: variant1, quantity: 1, order: order1)
          create(:line_item_with_shipment, variant: variant2, quantity: 3, order: order1)
          create(:line_item_with_shipment, variant: variant1, quantity: 2, order: order2)
          create(:line_item_with_shipment, variant: variant3, quantity: 1, order: order2)
        end

        it "includes only selected product" do
          tomselect_search_and_select(variant3.sku, from: "variant_id_in[]")
          run_report

          rows = find("table.report__table").all("tbody tr")
          table = rows.map { |r| r.all("td").map { |c| c.text.strip } }
          expect(table).to have_content(variant3.product.name)
          expect(table).not_to have_content(product.name)

          # Check the product dropdown still show the selected product
          selected_product = page
            .find("[name='variant_id_in[]']")
            .sibling(".ts-wrapper")
            .first(".ts-control")
            .first(".item")
          expect(selected_product.text).to have_content(variant3.product.name)
        end
      end

      context "when voucher is applied to the order" do
        let(:voucher) { create(:voucher_percentage_rate, enterprise: distributor) }

        before do
          within_multi_select("Columns") do
            check "Voucher Label"
            check "Voucher Amount ($)"
          end
        end

        it 'displays the voucher label and amount values for the orders with voucher applied' do
          voucher.create_adjustment(voucher.code, order1)
          # mocking the total and pre_discount_total values
          total_before_discount = BigDecimal(20)
          total_after_discount = BigDecimal(15)
          order1.update_columns(total: total_after_discount)
          allow(order1).to receive(:pre_discount_total).and_return(total_before_discount)
          discounted_amount = total_before_discount - total_after_discount

          run_report

          within '.report__table' do
            expect(page).to have_content(voucher.code)
            expect(page).to have_content(discounted_amount)
          end
        end
      end
    end

    describe "Order Cycle Supplier" do
      context "for three different orders" do
        let(:order3) {
          create(:completed_order_with_totals, line_items_count: 0,
                                               distributor:,
                                               bill_address: bill_address1,
                                               order_cycle_id: order_cycle.id)
        }

        before do
          create(:line_item_with_shipment, variant: variant2, quantity: 4, order: order1)
          order3.finalize!
        end

        describe "Totals" do
          before do
            click_link "Order Cycle Supplier Totals"
          end

          context "with the header row option not selected" do
            before do
              find("#display_header_row").set(false) # hides the header row
              run_report
            end

            it "displays the report" do
              rows = find("table.report__table").all("thead tr")
              table = rows.map { |r| r.all("th").map { |c| c.text.strip } }

              # displays the producer column
              expect(table).to eq([
                                    ["Producer",
                                     "Product",
                                     "Variant",
                                     "Quantity",
                                     "Total Units",
                                     "Curr. Cost per Unit",
                                     "Total Cost"]
                                  ])

              # displays the producer name in the respective column
              # does not display the header row
              within "td" do
                expect(page).to have_content("Supplier Name")
                expect(page).not_to have_css("td.header-row")
              end
            end

            it "aggregates results per variant" do
              expect(all('table.report__table tbody tr').count).to eq(3)
              # 1 row per variant = 2 rows
              # 1 summary row
              # 3 rows total

              rows = find("table.report__table").all("tbody tr")
              table = rows.map { |r| r.all("td").map { |c| c.text.strip } }

              expect(table).to include [
                "Supplier Name", "Baked Beans", "1g Big",
                "3", "0.003", "10.0", "30.0"
              ]

              expect(table).to include [
                "Supplier Name", "Baked Beans", "1g Small",
                "7", "0.007", "10.0", "70.0"
              ]
              expect(table[2]).to eq [
                "", "", "TOTAL",
                "10", "0.01", "", "100.0"
              ]
            end
          end

          context "with the header row option selected" do
            before do
              find("#display_header_row").set(true) # displays the header row
              run_report
            end

            it "displays the report" do
              rows = find("table.report__table").all("thead tr")
              table = rows.map { |r| r.all("th").map { |c| c.text.strip } }

              # hides the producer column
              expect(table).to eq([
                                    ["Product",
                                     "Variant",
                                     "Quantity",
                                     "Total Units",
                                     "Curr. Cost per Unit",
                                     "Total Cost"]
                                  ])

              # displays the producer name in own row
              within "td.header-row" do
                expect(page).to have_content("Supplier Name")
              end
            end
          end
        end

        describe "Totals by Distributor" do
          context "as the distributor" do
            let(:current_user) { distributor.owner }

            before do
              login_as(current_user)
              visit admin_reports_path
              click_link "Order Cycle Supplier Totals by Distributor"
            end

            context "with the header row option not selected" do
              before do
                find("#display_header_row").set(false) # hides the header row
                run_report
              end

              it "displays the report" do
                # displays the producer column
                expect(table_headers).to eq([
                                              ["Producer",
                                               "Product",
                                               "Variant",
                                               "Hub",
                                               "Quantity",
                                               "Curr. Cost per Unit",
                                               "Total Cost",
                                               "Shipping Method"]
                                            ])

                # displays the producer name in the respective column
                # does not display the header row
                within "td" do
                  expect(page).to have_content("Supplier Name")
                  expect(page).not_to have_css("td.header-row")
                end
              end

              it "aggregates results per variant" do
                expect(all('table.report__table tbody tr').count).to eq(4)
                # 1 row per variant = 2 rows
                # 2 TOTAL rows
                # 4 rows total

                rows = find("table.report__table").all("tbody tr")
                table = rows.map { |r| r.all("td").map { |c| c.text.strip } }

                expect(table[0]).to eq(["Supplier Name", "Baked Beans", "1g Big",
                                        "Distributor Name", "3", "10.0", "30.0", "UPS Ground"])
                expect(table[1]).to eq(["", "", "", "TOTAL", "3", "", "30.0", ""])
                expect(table[2]).to eq(["Supplier Name", "Baked Beans", "1g Small",
                                        "Distributor Name", "7", "10.0", "70.0", "UPS Ground"])
                expect(table[3]).to eq(["", "", "", "TOTAL", "7", "", "70.0", ""])
              end
            end

            context "with the header row option selected" do
              before do
                find("#display_header_row").set(true) # displays the header row
                run_report
              end

              it "displays the report" do
                rows = find("table.report__table").all("thead tr")
                table = rows.map { |r| r.all("th").map { |c| c.text.strip } }

                # hides the producer column
                expect(table).to eq([
                                      ["Product",
                                       "Variant",
                                       "Quantity",
                                       "Curr. Cost per Unit",
                                       "Total Cost",
                                       "Shipping Method"]
                                    ])

                # displays the producer name in own row
                within "td.header-row" do
                  expect(page).to have_content("Supplier Name")
                end
              end
            end
          end

          context "as the supplier granting P-OC to distributor" do
            let(:current_user) { supplier.owner }

            before do
              create(:enterprise_relationship, parent: supplier, child: distributor,
                                               permissions_list: [:add_to_order_cycle])

              login_as(current_user)
              visit admin_report_path(:orders_and_fulfillment,
                                      :order_cycle_supplier_totals_by_distributor)

              uncheck "Header Row"
              run_report
            end

            it "displays the report" do
              # displays the producer column
              expect(table_headers).to eq([
                                            ["Producer",
                                             "Product",
                                             "Variant",
                                             "Hub",
                                             "Quantity",
                                             "Curr. Cost per Unit",
                                             "Total Cost",
                                             "Shipping Method"]
                                          ])

              # displays the producer name in the respective column
              # does not display the header row
              within "td" do
                expect(page).to have_content("Supplier Name")
                expect(page).not_to have_css("td.header-row")
              end
            end

            it "aggregates results per variant" do
              rows = find("table.report__table").all("tbody tr")
              table = rows.map { |r| r.all("td").map { |c| c.text.strip } }

              expect(table.count).to eq(4)
              # 1 row per variant = 2 rows
              # 2 TOTAL rows for distributors
              # 4 rows total

              expect(table[0]).to eq(["Supplier Name", "Baked Beans", "1g Big",
                                      "Distributor Name", "3", "10.0", "30.0", "UPS Ground"])
              expect(table[1]).to eq(["", "", "", "TOTAL", "3", "", "30.0", ""])
              expect(table[2]).to eq(["Supplier Name", "Baked Beans", "1g Small",
                                      "Distributor Name", "7", "10.0", "70.0", "UPS Ground"])
              expect(table[3]).to eq(["", "", "", "TOTAL", "7", "", "70.0", ""])
            end
          end
        end
      end
    end

    describe "Order Cycle Distributor Totals by Supplier" do
      context "for an OC supplied by two suppliers" do
        let(:supplier2) { create(:supplier_enterprise, name: "Another Supplier Name") }
        let(:product2) {
          create(:simple_product, name: "Salted Peanuts", supplier_id: supplier2.id )
        }
        let(:variant3) {
          create(:variant, product: product2, unit_description: "Bag", supplier: supplier2)
        }
        let(:order4) {
          create(:completed_order_with_totals, line_items_count: 0, distributor:,
                                               bill_address: bill_address1,
                                               order_cycle_id: order_cycle.id)
        }

        before do
          # order3 has one line items / variants
          create(:line_item_with_shipment, variant: variant3, quantity: 2, order: order4)
          order4.finalize!
          click_link "Order Cycle Distributor Totals by Supplier"
        end

        context "with the header row option not selected" do
          before do
            find("#display_header_row").set(false) # hides the header row
            run_report
          end

          it "displays the report" do
            # displays the producer column
            expect(table_headers).to eq([
                                          ["Hub",
                                           "Producer",
                                           "Product",
                                           "Variant",
                                           "Quantity",
                                           "Curr. Cost per Unit",
                                           "Total Cost",
                                           "Total Shipping Cost",
                                           "Shipping Method"]
                                        ])

            # displays the Distributor name in the respective column
            # does not display the header row
            within "td" do
              expect(page).to have_content("Distributor Name")
              expect(page).not_to have_css("td.header-row")
            end
          end

          xit "aggregates results per variant, per supplier" do
            pending '#9678'
            expect(all('table.report__table tbody tr').count).to eq(4)
            # 1 row per supplier, per variant = 3 rows
            # 1 TOTAL rows
            # 4 rows total

            expect(table_headers[0]).to eq(
              ["Distributor Name", "Another Supplier Name", "Salted Peanuts",
               "1g Bag, S", "2", "10.0", "20.0", "", "UPS Ground"]
            )
            expect(table_headers[1]).to eq(
              ["Distributor Name", "Supplier Name", "Baked Beans",
               "1g Small, S", "3", "10.0", "30.0", "", "UPS Ground"]
            )
            expect(table_headers[2]).to eq(
              ["Distributor Name", "Supplier Name", "Baked Beans",
               "1g Big, S", "3", "10.0", "30.0", "", "UPS Ground"]
            )
            expect(table_headers[3]).to eq(["", "", "", "", "", "TOTAL", "80.0", "0.0", ""])
          end
        end

        context "with the header row option selected" do
          before do
            find("#display_header_row").set(true) # displays the header row
          end

          it "displays the report" do
            run_report

            # hides the Hub column
            expect(table_headers).to eq([
                                          ["Producer",
                                           "Product",
                                           "Variant",
                                           "Quantity",
                                           "Curr. Cost per Unit",
                                           "Total Cost",
                                           "Total Shipping Cost",
                                           "Shipping Method"]
                                        ])

            # displays the Distributor name in own row
            within "td.header-row" do
              expect(page).to have_content("Hub #{distributor.name}")
            end
          end
        end
      end
    end

    describe "Saving report rendering options" do
      let(:report_title) { "Order Cycle Supplier Totals" }

      let(:second_report_title) { "Order Cycle Supplier Totals by Distributor" }

      let(:columns_dropdown_selector) { 'div[data-multiple-checked-select-target="button"]' }

      context "Switching between reports" do
        context "Display options" do
          it "should store display options for every report separately" do
            # Step 1: Update report rendering options on two reports
            click_link report_title
            expect(page).to have_unchecked_field('Header Row')
            expect(page).to have_checked_field('Summary Row')
            check 'Header Row'
            uncheck 'Summary Row'

            run_report

            click_link "Report"
            click_link second_report_title
            expect(page).to have_unchecked_field('Header Row')
            expect(page).to have_checked_field('Summary Row')
            check 'Header Row'
            run_report

            # Step 2: check if report rendering options are saved properly
            click_link "Report"
            click_link report_title
            expect(page).to have_checked_field('Header Row')
            expect(page).to have_unchecked_field('Summary Row')

            click_link "Report"
            click_link second_report_title
            expect(page).to have_checked_field('Header Row')
            expect(page).to have_checked_field('Summary Row')
          end
        end

        context "Columns to show" do
          it "should store columns to show for every report separately" do
            # Step 1: Update report rendering options on two reports
            click_link report_title

            find(columns_dropdown_selector).click
            expect(page).to have_checked_field('Producer')
            expect(page).to have_checked_field('Product')
            uncheck('Producer')
            uncheck('Product')
            run_report

            click_link "Report"
            click_link second_report_title

            find(columns_dropdown_selector).click
            expect(page).to have_checked_field('Producer')
            expect(page).to have_checked_field('Product')
            uncheck('Product')
            run_report

            # Step 2: check if report rendering options are saved properly
            click_link "Report"
            click_link report_title

            find(columns_dropdown_selector).click
            expect(page).to have_unchecked_field('Producer')
            expect(page).to have_unchecked_field('Product')

            click_link "Report"
            click_link second_report_title

            find(columns_dropdown_selector).click
            expect(page).to have_checked_field('Producer')
            expect(page).to have_unchecked_field('Product')
          end
        end
      end

      context "Revisiting a report after logout" do
        context "Display options" do
          it "should store display options" do
            click_link report_title
            expect(page).to have_unchecked_field('Header Row')
            expect(page).to have_checked_field('Summary Row')
            check 'Header Row'
            uncheck 'Summary Row'
            run_report

            logout
            login_as(current_user)
            visit admin_reports_path

            click_link report_title
            expect(page).to have_checked_field('Header Row')
            expect(page).to have_unchecked_field('Summary Row')
          end
        end

        context "Columns to show" do
          it "should store columns after logout" do
            click_link report_title

            find(columns_dropdown_selector).click
            expect(page).to have_checked_field('Producer')
            expect(page).to have_checked_field('Product')
            uncheck('Producer')
            uncheck('Product')
            run_report

            logout
            login_as(current_user)
            visit admin_reports_path

            click_link "Report"
            click_link report_title

            find(columns_dropdown_selector).click
            expect(page).to have_unchecked_field('Producer')
            expect(page).to have_unchecked_field('Product')
          end
        end
      end
    end
  end

  def within_multi_select(text)
    find(".label", text:).click # open
    yield
    find(".label", text:).click # close
  end
end
